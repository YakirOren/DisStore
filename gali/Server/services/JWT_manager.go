package services

import (
	"context"
	"time"

	"github.com/dgrijalva/jwt-go"
	codes "google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// JWTManager handels the JWT actions.
type JWTManager struct {
	AccessTokenDuration  time.Duration
	RefreshTokenDuration time.Duration
	AccessTokenKey       string
	RefreshTokenKey      string
}

/*
UserClaims is a custom JWT claims that contains some user info.
the UserClaims is part of the JWT token.
*/
type UserClaims struct {
	jwt.StandardClaims
	Email string `json:"email"`
	Role  string `json:"role"`
}

// NewJWTManager creates a new JWTManager.
func NewJWTManager(
	AccessTokenDuration,
	RefreshTokenDuration,
	AccessTokenKey,
	RefreshTokenKey string) (*JWTManager, error) {

	_AccessTokenDuration, err := time.ParseDuration(AccessTokenDuration)
	if err != nil {
		return nil, err
	}

	_RefreshTokenDuration, err := time.ParseDuration(RefreshTokenDuration)
	if err != nil {
		return nil, err
	}

	return &JWTManager{_AccessTokenDuration, _RefreshTokenDuration, AccessTokenKey, RefreshTokenKey}, nil
}

// GenerateAccessToken Generate and sings a new token for a given user.
func (manager *JWTManager) GenerateAccessToken(user *User) (string, error) {
	return manager.Generate(user, manager.AccessTokenDuration, manager.AccessTokenKey)
}

// GenerateRefreshToken Generate and sings a new token for a given user.
func (manager *JWTManager) GenerateRefreshToken(user *User) (string, error) {
	return manager.Generate(user, manager.RefreshTokenDuration, manager.RefreshTokenKey)
}

// Generate creates a token.
func (manager *JWTManager) Generate(user *User, t time.Duration, key string) (string, error) {

	claims := UserClaims{
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(t).Unix(),
		},
		Email: user.Email,
		Role:  user.Role,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims) // change this to a more secure method!!

	return token.SignedString([]byte(key))
}

// VerifyAccessToken Verifies the given token and returns a UserClaims if valid.
func (manager *JWTManager) VerifyAccessToken(accessToken string) (*UserClaims, error) {

	token, err := jwt.ParseWithClaims(
		accessToken,
		&UserClaims{},

		func(token *jwt.Token) (interface{}, error) {
			_, ok := token.Method.(*jwt.SigningMethodHMAC) //TODO change this to a more secure method!!

			if !ok {
				return nil, status.Errorf(codes.InvalidArgument, "Invalid token")
			}

			return []byte(manager.AccessTokenKey), nil
			// if the token uses the same signing method as our server,
			// we send ParseWithClaims the manager's secret key so we can decode it.
		},
	)

	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid token")
	}

	claims, ok := token.Claims.(*UserClaims)

	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid token")
	}

	return claims, nil

}

// VerifyRefreshToken Verifies the given token and returns a UserClaims if valid.
func (manager *JWTManager) VerifyRefreshToken(RefreshToken string) (*UserClaims, error) {

	token, err := jwt.ParseWithClaims(
		RefreshToken,
		&UserClaims{},

		func(token *jwt.Token) (interface{}, error) {
			_, ok := token.Method.(*jwt.SigningMethodHMAC) //TODO change this to a more secure method!!

			if !ok {
				return nil, status.Errorf(codes.InvalidArgument, "Invalid token")
			}

			return []byte(manager.RefreshTokenKey), nil
			// if the token uses the same signing method as our server,
			// we send ParseWithClaims the manager's secret key so we can decode it.
		},
	)

	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid token")
	}

	claims, ok := token.Claims.(*UserClaims)
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid token")
	}

	return claims, nil

}

// ExtractClaims gets the email field from the ctx.
func (manager *JWTManager) ExtractClaims(ctx context.Context) (*UserClaims, error) {
	metaData, ok := metadata.FromIncomingContext(ctx) // extract metadata form ctx
	if !ok {
		return &UserClaims{}, status.Errorf(codes.Unauthenticated, "Metadata not provided")
	}

	values := metaData["authorization"] // check if the user provided a token
	if len(values) == 0 {
		return &UserClaims{}, status.Errorf(codes.Unauthenticated, "Authorization token is not provided")
	}

	accessToken := values[0]                              // the access token is always in the first cell
	claims, err := manager.VerifyAccessToken(accessToken) // check if the token is valid
	if err != nil {
		return &UserClaims{}, status.Errorf(codes.Unauthenticated, "Invalid access token")
	}

	return claims, nil
}
