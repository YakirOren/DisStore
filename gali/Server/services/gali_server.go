package services

import (
	"bytes"
	"context"
	"io"
	"time"

	pb "cloud/gali/Server/protos"

	_ "github.com/sirupsen/logrus"
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
func (server *GaliServer) GetUserInfo(ctx context.Context, in *pb.UserInfoRequest) (*pb.UserInfoResponse, error) {

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

func (server *GaliServer) GetAllFiles(in *pb.FileRequest, stream pb.Gali_GetAllFilesServer) error {
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

		if err := stream.Send(&pb.FileInfo{Name: file.Name, Id: file.ID.String()[10 : len(file.ID.String())-2]}); err != nil {
			return status.Errorf(codes.Internal, "Something went wrong!")
		}
	}

	return nil
}

func (server *GaliServer) GetFile(ctx context.Context, in *pb.FileInfo) (*pb.GenericFile, error) {

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
		return &pb.GenericFile{Metadata: &pb.FileInfo{Name: file.Name, Id: file.ID.String()}, Fragments: file.Fragments, CreationTime: file.Time}, nil
	}
	return nil, status.Errorf(codes.PermissionDenied, "you dont have the permissions to this resource")

}

func (server *GaliServer) DeleteFile(ctx context.Context, in *pb.FileInfo) (*pb.StatusResponse, error) {

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
	fileName := req.GetMetadata().Name

	log.Println(fileName)
	//getting the content of the file.

	fileData := bytes.Buffer{}

	fileSize := int64(0)
	for {
		//log.Println(fileSize)
		err := contextError(stream.Context())
		if err != nil {
			return err
		}

		//log.Print("waiting to receive more data")

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

		//TODO: dont load the entire file on the ram
		// upload parts of the file when uploading

		if err != nil {
			return status.Errorf(codes.Internal, "file writing failed")
		}

	}

	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(stream.Context())
	if err != nil {
		return err
	}

	// upload the file to discord and get the file fragmets back as []string
	frags := server.discordManager.UploadFile(fileData, fileSize)
	// store the fragments in the database
	// create a new file in the file collection.
	server.mongoDBWrapper.AddFile(&File{Owner: claims.Email, Name: fileName, Fragments: frags, Time: time.Now().Unix()})

	// tell the users that everything is OK.
	err = stream.SendAndClose(&pb.StatusResponse{})
	if err != nil {
		return status.Errorf(codes.Unknown, "stream fail")
	}
	return nil
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
