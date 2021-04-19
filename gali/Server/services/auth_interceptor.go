package services

import (
	"context"

	log "github.com/sirupsen/logrus"

	"google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

//AuthInterceptor Is a server intercepor for authentication and autharization
type AuthInterceptor struct {
	jwtManager      *JWTManager
	accessibleRoles map[string][]string
}

//NewAuthInterceptor Returns a new auth interceptor
func NewAuthInterceptor(jwtManager *JWTManager, accessibleRole map[string][]string) *AuthInterceptor {
	return &AuthInterceptor{jwtManager, accessibleRole}
}

//Unary Returns a server interceptor function to authenticate and authorize unary RPC
func (interceptor *AuthInterceptor) Unary() grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (interface{}, error) {

		log.Debug("Call to RPC --→ ", info.FullMethod)
		err := interceptor.authorize(ctx, info.FullMethod)
		if err != nil {
			log.Debug(err)
			return nil, err
		}

		return handler(ctx, req)
	}
}

// //Stream Returns a server interceptor function to authenticate and authorize stream RPC
// func (interceptor *AuthInterceptor) Stream() grpc.StreamServerInterceptor {
// 	return func(
// 		srv interface{},
// 		stream grpc.ServerStream,
// 		info *grpc.StreamServerInfo,
// 		handler grpc.StreamHandler,
// 	) (interface{}, error) {
// 		log.Println("[DEBUG] This is the STREAM interceptor: ", info.FullMethod)

// 		err := interceptor.authorize(stream.Context(), info.FullMethod)
// 		if err != nil {
// 			return nil, err
// 		}

// 		return handler(srv, stream)
// 	}
// }

func (interceptor *AuthInterceptor) authorize(ctx context.Context, method string) error {
	accessibleRoles, ok := interceptor.accessibleRoles[method]
	if !ok { // check if everyone can access the method
		return nil
	}

	claims, err := interceptor.jwtManager.ExtractClaims(ctx)
	if err != nil {
		return err
	}

	// check if the user has a role
	for _, role := range accessibleRoles {
		if role == claims.Role {
			return nil // reutrn nil to authorize the
		}
	}

	return status.Errorf(codes.Unauthenticated, "no permission to access this RPC")
}
