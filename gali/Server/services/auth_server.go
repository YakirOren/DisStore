package services

import (
	"context"
	"net"
	"regexp"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	pb "cloud/gali/Server/protos"

	"github.com/go-passwd/validator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/peer"
	"google.golang.org/grpc/status"
)

// AuthServer manages the authentication
type AuthServer struct {
	mongoDBWrapper MongoDBWrapper
	jwtManager     *JWTManager
	emailManager   *EmailManager
}

// NewAuthServer creates a new authentication server
func NewAuthServer(mongoDBWrapper MongoDBWrapper, jwtManager *JWTManager, emailManager *EmailManager) *AuthServer {
	return &AuthServer{mongoDBWrapper, jwtManager, emailManager}
}

// Login checks if the details are good and sends a new jet token to the user
func (server *AuthServer) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
	// find the user in the database.
	user, err := server.mongoDBWrapper.GetUserByEmail(req.GetMail())
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Invalid username or password")
	}

	// check if the password is correct
	if user == nil || user.validatePassword(req.GetPassword()) != nil {
		return nil, status.Errorf(codes.NotFound, "Invalid username or password")
	}

	if !user.Activated {
		return nil, status.Errorf(codes.PermissionDenied, "User not verified")
	}

	accessToken, refreshToken, expiresAt, err := server.GenerateTokens(user)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	// logging the device identifier
	if len(req.GetIdentifier()) == 0 {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}
	isNew, err := server.mongoDBWrapper.CheckIdentifier(req.GetMail(), req.GetIdentifier())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}
	if isNew {
		// get the ip from the context
		p, ok := peer.FromContext(ctx)
		if !ok {
			return nil, status.Errorf(codes.Internal, "Something went wrong!")
		}
		deviceIPAndPort := p.Addr.String()
		deviceIP := strings.Split(deviceIPAndPort, ":")[0]

		// send the user that a new device was recorded, dont log the user in if it fails to send
		err = server.emailManager.SendNewLoginMessage(user, req.GetDeviceName(), deviceIP)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Something went wrong!")
		}
		// add the device to the DB
		err = server.mongoDBWrapper.AddIdentifier(req.GetMail(), req.GetIdentifier())
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Something went wrong!")
		}
	}

	log.WithFields(log.Fields{"email": user.Email}).Info("Login")

	// sending a new JWT token, expire time, new refresh token.
	res := &pb.LoginResponse{AccessToken: accessToken, ExpiresOn: expiresAt, RefreshToken: refreshToken}
	return res, nil
}

// RefreshToken will generate a new token for the user
func (server *AuthServer) RefreshToken(ctx context.Context, req *pb.RefreshTokenRequest) (*pb.LoginResponse, error) {

	// get the userclims from the refresh token
	userClaims, err := server.jwtManager.VerifyRefreshToken(req.GetRefreshToken())
	if err != nil {
		return nil, err
	}

	// get the user from the user claims.
	user, err := server.mongoDBWrapper.GetUserByEmail(userClaims.Email)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	// verify refresh token against database.
	if user.RefreshToken != req.GetRefreshToken() {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	accessToken, refreshToken, expiresAt, err := server.GenerateTokens(user)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	// sending a new JWT token, expire time, new refresh token.
	res := &pb.LoginResponse{AccessToken: accessToken, ExpiresOn: expiresAt, RefreshToken: refreshToken}
	return res, nil

}

func (server *AuthServer) ValidatePassword(firstName, lastName, email, password string) error {

	passwordValidator := validator.New(
		validator.MinLength(
			5,
			status.Errorf(codes.InvalidArgument, "Password is too short")),
		validator.ContainsAtLeast(
			"~<=>+-@!#$%^&*",
			1,
			status.Errorf(codes.InvalidArgument, "Password must contain at least 1 special character(~<=>+-@!#$%%^&*)")), // %% is escaping the %
		validator.CommonPassword(nil),
		validator.Similarity(
			[]string{
				firstName,
				lastName,
				email},
			nil,
			nil))
	err := passwordValidator.Validate(password)

	if err != nil {
		return err
	}

	return nil

}

// Register creates a new user.
func (server *AuthServer) Register(ctx context.Context, req *pb.RegisterRequest) (*pb.StatusResponse, error) {

	user, err := NewUser(req.GetFirstName(), req.GetLastName(), req.GetMail(), req.GetPassword(), "user")

	if err != nil {
		return nil, err
	}
	err = server.ValidatePassword(req.GetFirstName(), req.GetLastName(), req.GetMail(), req.GetPassword())
	if err != nil {
		return nil, err
	}

	if !IsEmailValid(req.GetMail()) {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid mail format!")
	}

	err = server.mongoDBWrapper.AddUser(user)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong while creating the user!")
	}

	if !userOnTimeout(user) {
		err = server.emailManager.SendVerficationCode(user)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Couldn't send verfication code")
		}
	}

	return &pb.StatusResponse{}, nil
}

// IsEmailValid checks if the email provided passes the required structure
// and length test. It also checks the domain has a valid MX record.
func IsEmailValid(mail string) bool {
	var emailRegex = regexp.MustCompile("^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")

	// mail must be bigger then 3 characters long and less then 254
	if len(mail) < 3 && len(mail) > 254 {
		return false
	}

	if !emailRegex.MatchString(mail) {
		return false
	}

	parts := strings.Split(mail, "@")
	mx, err := net.LookupMX(parts[1])
	if err != nil || len(mx) == 0 {
		return false
	}

	return true
}

// GenerateTokens will generate new access token, refresh token and thier expiration time for the given user
func (server *AuthServer) GenerateTokens(user *User) (accessToken string, refreshToken string, expiresAt int64, err error) {
	// generate JWT tokenn
	accessToken, err = server.jwtManager.GenerateAccessToken(user) // create a new token
	if err != nil {
		return
	}

	// generate refresh token
	refreshToken, err = server.jwtManager.GenerateRefreshToken(user) // create a new token
	if err != nil {
		return
	}

	// get userclaims from the token so we could get the expire time.
	userClaims, err := server.jwtManager.VerifyAccessToken(accessToken)
	if err != nil {
		return
	}

	// save the refresh token in the database.
	if server.mongoDBWrapper.SetRefreshToken(user.Email, refreshToken) != nil {
		return
	}

	expiresAt = userClaims.ExpiresAt

	return
}

// Verify handles verifying and activating users.
func (server *AuthServer) Verify(ctx context.Context, req *pb.VerifyRequest) (*pb.StatusResponse, error) {

	// find the user in the database.
	user, err := server.mongoDBWrapper.GetUserByEmail(req.GetMail())
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Invalid username or password")
	}

	if user.VerficationCode != req.GetCode() {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid code")
	}

	err = server.mongoDBWrapper.ActivateUser(user.Email)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Activation failed")
	}

	return &pb.StatusResponse{}, nil
}

// GetVerifyCode send the user a new code to their mail, if they are not on timeout.
func (server *AuthServer) GetVerifyCode(ctx context.Context, req *pb.CodeRequest) (*pb.StatusResponse, error) {

	// get the user from the mail
	// find the user in the database.
	user, err := server.mongoDBWrapper.GetUserByEmail(req.GetMail())
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Invalid username or password")
	}

	// check if the user is not on timeout

	if userOnTimeout(user) {
		return nil, status.Errorf(codes.Unavailable, "please wait between requests")
	}

	// generate a new verification code.
	user.VerficationCode, err = server.refreshCode(user)
	if err != nil {
		return nil, err
	}

	// send the user a mail with a new verification code.
	err = server.emailManager.SendVerficationCode(user)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Couldn't send verfication code")
	}

	return &pb.StatusResponse{}, nil
}

// Verify handles verifying and activating users.
func (server *AuthServer) ResetPassword(ctx context.Context, req *pb.ResetPasswordRequest) (*pb.StatusResponse, error) {

	// find the user in the database.
	user, err := server.mongoDBWrapper.GetUserByEmail(req.GetMail())
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Invalid username or password")
	}

	// if the code is empty and he isnt on a cooldown send a mail
	if len(req.GetCode()) == 0 {
		if userOnTimeout(user) {
			return nil, status.Errorf(codes.Unavailable, "Please wait between requests")
		}

		// generate a new verification code.
		user.VerficationCode, err = server.refreshCode(user)
		if err != nil {
			return nil, err
		}

		// send the user a mail with a new verification code.
		err = server.emailManager.SendResetPasswordMessage(user)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Couldn't send verfication code")
		}

		return &pb.StatusResponse{}, nil // tell the user we created a code and didnt raise an error
	}

	if user.VerficationCode != req.GetCode() {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid code")
	}

	err = server.ValidatePassword(user.FirstName,
		user.LastName,
		user.Email, req.GetPassword())
	if err != nil {
		return nil, err
	}

	err = server.mongoDBWrapper.ChangePassword(user.Email, req.GetPassword())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	// generate a new verification code so the same code cannot be used in order to change the password again
	user.VerficationCode, err = server.refreshCode(user)
	if err != nil {
		return nil, err
	}

	return &pb.StatusResponse{}, nil
}

// refreshCode generates a new verification code and updates the database.
func (server *AuthServer) refreshCode(user *User) (string, error) {
	// generate a new verification code.
	var err error
	user.VerficationCode, err = generateNewCode(6)
	if err != nil {
		return "", status.Errorf(codes.Internal, "Something went wrong!")
	}
	// set it in the DB
	err = server.mongoDBWrapper.SetVerficationCode(user.Email, user.VerficationCode)
	if err != nil {
		return "", status.Errorf(codes.Internal, "Something went wrong!")
	}
	err = server.mongoDBWrapper.ResetLastCodeRequest(user.Email)
	if err != nil {
		return "", status.Errorf(codes.Internal, "Something went wrong!")
	}

	return user.VerficationCode, nil
}

// userOnTimeout checks if the is on timeout
// if the user is on timeout he cannot call ciretin functions.
func userOnTimeout(user *User) bool {
	currTime := time.Now().Unix()

	// 300 is 5 min
	return currTime-user.LastCodeRequest <= 300
}
