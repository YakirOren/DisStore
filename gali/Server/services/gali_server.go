package services

import (
	"bytes"
	"context"
	"io"
	"math"
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

	return &pb.UserInfoResponse{FirstName: user.FirstName, LastName: user.LastName, Mail: user.Email, UsedStorage: user.UsedStorageSpace}, nil
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
		if err := stream.Send(&pb.FileInfo{Name: file.Name, Id: file.ID.Hex(), CreationTime: file.Time, FileSize: float32(file.FileSize)}); err != nil {
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

	// check if user owns the requested file.
	if file.Owner == user.Email {
		err = server.mongoDBWrapper.RemoveFile(in.Id)
		if err != nil {
			return nil, err
		}

		err = server.mongoDBWrapper.IncUsedStorage(user.Email, -file.FileSize)
		if err != nil {
			return nil, err
		}

		return &pb.StatusResponse{}, nil
	}
	return nil, status.Errorf(codes.PermissionDenied, "you dont have the permissions to this resource")

}

// turns out you cant have const byte slice in golang,
// so I created this funciton to return the gif header.
func getGIFHeader() []byte {
	return []byte{0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x3B}
}

const (
	GIFHeaderSize = 14
)

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

	fileCount := int(0) // starting with 0 files and incrementing if the file is larger then the maximum size.

	// create a new file in the file collection.
	id, err := server.mongoDBWrapper.AddFile(&File{Owner: claims.Email, Name: fileName, Fragments: []string{}, Time: time.Now().Unix(), FileSize: 0.0})
	check(err)

	fileData := bytes.Buffer{}

	// add the gif header to the start of the file.
	fileData.Write(getGIFHeader())
	// add the size of the gif header.
	fileSize := int64(GIFHeaderSize)

	for {
		err := contextError(stream.Context())
		if err != nil {
			return err
		}

		req, err := stream.Recv()
		if err == io.EOF {
			// no more data
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

			newFile := make([]byte, maximumSize) // creating array to store the file.
			fileData.Read(newFile)               // read from the buffer and store it in the array.

			log.Println("Sending file 🚀: " + strconv.Itoa(fileCount))

			// sending the array to discord.
			go server.SendToDiscord(newFile, id, fileCount)

			fileSize -= maximumSize
			fileCount++

			// add the gif header to the next file.
			fileData.Write(getGIFHeader())
			// add the size of the gif header.
			fileSize += int64(GIFHeaderSize)

		}

	}

	// send the rest of the data...
	newFile := make([]byte, fileData.Len())
	fileData.Read(newFile)

	log.Println("sending file 🚀: " + strconv.Itoa(fileCount))
	go server.SendToDiscord(newFile, id, fileCount)

	fileSize += int64(int64(fileCount) * maximumSize)

	size := float64(float64(fileSize) / math.Pow10(9)) // convert bytes to gb

	// update the file stats in the database.
	err = server.mongoDBWrapper.IncUsedStorage(claims.Email, size)
	check(err)

	err = server.mongoDBWrapper.IncFileSize(id, size)
	check(err)

	// tell the users that everything is OK 👌.
	err = stream.SendAndClose(&pb.StatusResponse{})
	if err != nil {
		return status.Errorf(codes.Unknown, "stream fail")
	}
	return nil
}

// SendToDiscord
func (server *GaliServer) SendToDiscord(fileData []byte, fileID string, fileCount int) {

	discordMsg := server.discordManager.UploadOneFile(fileData, fileCount)

	// add the new url to the file document
	err := server.mongoDBWrapper.addURL(fileID, discordMsg.Attachments[0].URL)
	check(err)

	log.Println("Added " + discordMsg.Attachments[0].URL)

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
