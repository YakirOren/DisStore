package main

import (
	"net"

	log "github.com/sirupsen/logrus"

	pb "cloud/gali/Server/protos"
	"cloud/gali/Server/services"
	"cloud/gali/Server/util"

	"google.golang.org/grpc"

	"github.com/joho/godotenv"
	"google.golang.org/grpc/reflection"
)

func accessibleRoles() map[string][]string {
	const path = "/gali.gali/"
	return map[string][]string{
		path + "GetUserInfo":     {"user"},
	}

}

// init is invoked before main()
func init() {
	// loads values from .env into the system
	if err := godotenv.Load("config.env"); err != nil {
		log.Warning("No .env file found")
	}

	// log debuglevel or higher
	log.SetLevel(log.DebugLevel)
}

func main() {
	config, err := util.LoadConfig(".")
	if err != nil {
		log.Fatal("❌\n", err)
	}

	mongoDBWrapper := services.NewMongoDBWrapper(config.ConnectionString, config.DBName, config.UserCollection, config.FileCollection, config.LogsCollection)
	log.Info("Connecting to DB...")
	mongoDBWrapper.Connect()
	defer mongoDBWrapper.Disconnect()
	mongoDBWrapper.CheckConnection()
	jwtManager, err := services.NewJWTManager(config.AccessTokenDuration, config.RefreshTokenDuration, config.AccessTokenKey, config.RefreshTokenKey)
	emailManager := services.NewEmailManager(config.SystemEmail, config.SystemEmailPassword)

	if err != nil {
		log.Fatal("❌\n", err)
	}

	authServer := services.NewAuthServer(*mongoDBWrapper, jwtManager, emailManager)
	logic := services.NewPayeetServer(*mongoDBWrapper, jwtManager)

	interceptor := services.NewAuthInterceptor(jwtManager, accessibleRoles())
	srv := grpc.NewServer(
		grpc.UnaryInterceptor(interceptor.Unary()),
	)

	pb.RegisterPayeetAuthServer(srv, authServer)
	pb.RegisterPayeetServer(srv, logic)
	reflection.Register(srv)

	log.Infof("Starting server on port [%s]", config.Port)
	listener, err := net.Listen("tcp", ":"+config.Port)
	if err != nil {
		log.Fatal(err)
	}
	log.Info("Done! ✅")

	log.Info("Serving... 🥳")
	
	//log.Info("All logs now will be logged to the MongoDB database!... 📃")
	//log.SetOutput(mongoDBWrapper)

	// start logging as JSON
	log.SetFormatter(&log.JSONFormatter{})

	log.Info("Server up")
	if err := srv.Serve(listener); err != nil {
		log.Fatal("❌\n", err)
	}

}
