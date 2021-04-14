package services

import (
	"context"

	pb "cloud/gali/Server/protos"

	_ "github.com/sirupsen/logrus"

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

func (server *GaliServer) GetFiles(in *pb.FileRequest, stream pb.Gali_GetFilesServer) error {
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
		stream.Send(&pb.GenericFile{Owner: file.Owner, Name: file.Name, Fragments: file.Fragments, Time: file.Time})
	}
	return nil
}

func (server *GaliServer) Upload(ctx context.Context) error {

	return nil
}
