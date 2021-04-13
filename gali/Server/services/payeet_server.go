package services

import (
	"context"

	pb "cloud/gali/Server/protos"

	_ "github.com/sirupsen/logrus"

	codes "google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// PayeetServer is the logic for the server
type PayeetServer struct {
	mongoDBWrapper MongoDBWrapper
	jwtManager     *JWTManager
}

// NewPayeetServer creates a logic server
func NewPayeetServer(mongoDBWrapper MongoDBWrapper, jwtManager *JWTManager,) *PayeetServer {
	return &PayeetServer{mongoDBWrapper, jwtManager}
}


// GetUserInfo returns the blances of the user.
func (server *PayeetServer) GetUserInfo(ctx context.Context, in *pb.UserInfoRequest) (*pb.UserInfoResponse, error) {

	// get the claims from ctx.
	claims, err := server.jwtManager.ExtractClaims(ctx)
	if err != nil {
		return nil, err
	}

	user, err := server.mongoDBWrapper.GetUserByEmail(claims.Email)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "")
	}

	return &pb.UserInfoResponse{FirstName: user.FirstName, LastName: user.LastName, Mail: user.Email,}, nil
}

