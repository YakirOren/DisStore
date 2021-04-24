package services

import (
	"bytes"
	"context"
	"io"
	"io/ioutil"
	"math"
	"os"
	"strconv"
	"time"

	pb "cloud/gali/Server/protos"

	log "github.com/sirupsen/logrus"

	codes "google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// GaliServer is the logic for the server
type GaliServer struct {
	mongoDBWrapper MongoDBWrapper
	jwtManager     *JWTManager
	discordManager *DiscordManager
}

// NewGaliServer creates a logic server
func NewGaliServer(mongoDBWrapper MongoDBWrapper, jwtManager *JWTManager, discordManager *DiscordManager) *GaliServer {
	return &GaliServer{mongoDBWrapper, jwtManager, discordManager}
}

// GetUserInfo returns the blances of the user.
func (server *GaliServer) GetUserInfo(ctx context.Context, in *pb.Empty) (*pb.UserInfoResponse, error) {

	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(ctx)
	if err != nil {
		return nil, err
	}

	user, err := server.mongoDBWrapper.GetUserByEmail(claims.Email)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "")
	}

	return &pb.UserInfoResponse{FirstName: user.FirstName, LastName: user.LastName, Mail: user.Email}, nil
}

func (server *GaliServer) GetAllFiles(in *pb.Empty, stream pb.Gali_GetAllFilesServer) error {
	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(stream.Context())
	if err != nil {
		return err
	}

	user, err := server.mongoDBWrapper.GetUserByEmail(claims.Email)
	if err != nil {
		return err
	}

	// get the all files that are owned by the user.
	files, err := server.mongoDBWrapper.GetUserFiles(user.Email)
	if err != nil {
		return status.Errorf(codes.Internal, "Something went wrong!")
	}

	// send the files to the user in a stream.
	for _, file := range files {

		if err := stream.Send(&pb.FileInfo{Name: file.Name, Id: file.ID.Hex()}); err != nil {
			return status.Errorf(codes.Internal, "Something went wrong!")
		}
	}

	return nil
}

func (server *GaliServer) GetFile(ctx context.Context, in *pb.FileRequest) (*pb.GenericFile, error) {

	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(ctx)
	if err != nil {
		return nil, err
	}

	user, err := server.mongoDBWrapper.GetUserByEmail(claims.Email)
	if err != nil {
		return nil, err
	}

	file, err := server.mongoDBWrapper.GetFile(in.Id)
	if err != nil {
		return nil, err
	}

	log.Printf(file.Owner)
	log.Printf(user.Email)

	// check if user owns the requested file.
	if file.Owner == user.Email {
		return &pb.GenericFile{Metadata: &pb.FileInfo{Name: file.Name, Id: file.ID.String(), CreationTime: file.Time, FileSize: float32(file.FileSize)}, Fragments: file.Fragments}, nil
	}
	return nil, status.Errorf(codes.PermissionDenied, "you dont have the permissions to this resource")

}

func (server *GaliServer) DeleteFile(ctx context.Context, in *pb.FileRequest) (*pb.StatusResponse, error) {

	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(ctx)
	if err != nil {
		return nil, err
	}

	user, err := server.mongoDBWrapper.GetUserByEmail(claims.Email)
	if err != nil {
		return nil, err
	}

	file, err := server.mongoDBWrapper.GetFile(in.Id)
	if err != nil {
		return nil, err
	}

	log.Printf(file.Owner)
	log.Printf(user.Email)

	// check if user owns the requested file.
	if file.Owner == user.Email {
		err = server.mongoDBWrapper.RemoveFile(in.Id)
		if err != nil {
			return nil, err
		}

		return &pb.StatusResponse{}, nil
	}
	return nil, status.Errorf(codes.PermissionDenied, "you dont have the permissions to this resource")

}

func (server *GaliServer) Upload(stream pb.Gali_UploadServer) error {

	req, err := stream.Recv()
	if err != nil {
		return status.Errorf(codes.Unknown, "upload failed")
	}

	// getting the metadata of the file.
	fileName := req.GetFileName()

	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(stream.Context())
	if err != nil {
		return err
	}

	fileCount := int(0)

	// create a new file in the file collection.
	id, err := server.mongoDBWrapper.AddFile(&File{Owner: claims.Email, Name: fileName, Fragments: []string{}, Time: time.Now().Unix(), FileSize: 0.0})
	check(err)

	fileData := bytes.Buffer{}

	fileSize := int64(0)
	for {
		err := contextError(stream.Context())
		if err != nil {
			return err
		}

		req, err := stream.Recv()
		if err == io.EOF {
			log.Print("no more data")
			break
		}
		if err != nil {
			return status.Errorf(codes.Unknown, "upload failed")
		}

		// calculate the file size
		chunk := req.GetContent()
		size := int64(len(chunk))
		fileSize += size

		// add the new data to the data we already have.
		_, err = fileData.Write(chunk)
		if err != nil {
			return status.Errorf(codes.Internal, "file writing failed")
		}

		if fileSize >= maximumSize {

			newFile := make([]byte, maximumSize)
			fileData.Read(newFile) // read 8mb

			log.Println("sending file " + strconv.Itoa(fileCount))

			go server.SendToDiscord(newFile, id)
			fileSize -= maximumSize

			fileCount++

		}

	}

	//fileSize -= int64(fileData.Len())

	// send the rest of the data...
	newFile := make([]byte, fileData.Len())
	fileData.Read(newFile) // read 8mb

	log.Println("sending file " + strconv.Itoa(fileCount))
	go server.SendToDiscord(newFile, id)

	fileSize += int64(fileCount * maximumSize)

	size := float64(float64(fileSize) / math.Pow10(9)) // convert bytes to gb
	err = server.mongoDBWrapper.IncUsedStorage(claims.Email, size)
	check(err)

	err = server.mongoDBWrapper.IncFileSize(id, size)
	check(err)

	// tell the users that everything is OK.
	err = stream.SendAndClose(&pb.StatusResponse{})
	if err != nil {
		return status.Errorf(codes.Unknown, "stream fail")
	}
	return nil
}

// SendToDiscord
func (server *GaliServer) SendToDiscord(fileData []byte, fileID string) {

	fileName := "tmp"

	f2, err := ioutil.TempFile("", fileName)
	check(err)

	defer os.Remove(f2.Name())

	_, err = f2.Write(fileData)
	check(err)

	f2.Close()
	check(err)

	url := server.discordManager.UploadOneFile(fileData, f2.Name())

	log.Println("adding url")
	// add the new url to the file document
	server.mongoDBWrapper.addURL(fileID, url)
	check(err)

}

func contextError(ctx context.Context) error {
	switch ctx.Err() {
	case context.Canceled:
		return status.Error(codes.Canceled, "request is canceled")
	case context.DeadlineExceeded:
		return status.Error(codes.DeadlineExceeded, "deadline is exceeded")
	default:
		return nil
	}
}
