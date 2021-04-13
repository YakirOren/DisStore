package services

import (
	"context"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	"go.mongodb.org/mongo-driver/mongo/readpref"
	codes "google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// DBWrapper is an interface that handles fetching and updating the DB
type DBWrapper interface {
	Connect() error
	Disconnect() error

	AddUser(user *User) error
	AddFile(t *File) error

	GetUserByEmail(mail string) (*User, error)
	GetAllUsers() (a []*User, err error)

	SetRefreshToken(mail string, refreshToken string) error
	
	GetFiles(mail string) ([]*File, error)

	Write(message []byte) (int, error) // we must implement an io.Writer function to log into mongo



	ActivateUser(mail string) error

	CheckIdentifier(mail, identifier string) (bool, error)
	AddIdentifier(mail, identifier string) error

	SetVerficationCode(mail string, code string) error
	ResetLastCodeRequest(mail string) error

	ChangePassword(mail, newPassword string) error
}

// MongoDBWrapper is a warpper for mongodb
type MongoDBWrapper struct { // change name to db wapper or something

	// add collection for transactions.

	TransactionsCollection *mongo.Collection
	UsersCollection        *mongo.Collection
	LogsCollection         *mongo.Collection
	Client                 *mongo.Client

}

// NewMongoDBWrapper creates and returns a new object of the mongo wrapper
func NewMongoDBWrapper(ConnectionString, DBName, UserCollection, TransactionCollection, LogsCollection string) *MongoDBWrapper {

	client, err := mongo.NewClient(options.Client().ApplyURI(ConnectionString))
	if err != nil {
		log.Fatal(err)
	}

	return &MongoDBWrapper{
		TransactionsCollection: client.Database(DBName).Collection(TransactionCollection),
		UsersCollection:        client.Database(DBName).Collection(UserCollection),
		LogsCollection:         client.Database(DBName).Collection(LogsCollection),
		Client:                 client,
	}
}

// CheckConnection pings the database.
func (store *MongoDBWrapper) CheckConnection() {

	err := store.Client.Ping(context.TODO(), readpref.Primary())
	if err != nil {
		log.Fatalf("DB Connection failed.. ❌\n %v", err)
	}

	log.Info("Connected to DB successfully ✅")
}

// Connect makes a connection to the database.
func (store *MongoDBWrapper) Connect() error {

	err := store.Client.Connect(context.TODO())
	if err != nil {
		return err
	}

	return nil
}

// Disconnect closes the connection to the database.
func (store *MongoDBWrapper) Disconnect() error {

	err := store.Client.Disconnect(context.TODO())
	if err != nil {
		return err
	}

	return nil
}

// formatUser turns the fields in the User struct to lower letters
func formatUser(user *User) *User {

	user.FirstName = strings.ToLower(user.FirstName)
	user.LastName = strings.ToLower(user.LastName)
	user.Email = strings.ToLower(user.Email)

	return user
}


// AddUser adds a new user to the database.
func (store *MongoDBWrapper) AddUser(user *User) error {

	_, err := store.UsersCollection.InsertOne(
		context.TODO(),
		formatUser(user).ToBson(),
	)

	if err != nil {
		return status.Errorf(codes.Internal, "Something went wrong!")
	}

	return nil
}

// AddFile adds a new file to the file collection.
func (store *MongoDBWrapper) AddFile(t *File) error {

	_, err := store.TransactionsCollection.InsertOne(
		context.TODO(),
		t.ToBson(),
	)

	if err != nil {
		return status.Errorf(codes.Internal, "Something went wrong!")
	}

	return nil
}

// GetUserByEmail finds a user in the database that have the given mail
func (store *MongoDBWrapper) GetUserByEmail(mail string) (*User, error) {

	result := &User{}

	err := store.UsersCollection.FindOne(context.TODO(), bson.M{"Email": strings.ToLower(mail)}).Decode(&result)
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Invalid username or password")
	}

	return result, nil
}

// GetAllUsers returns every user stored user in the database
func (store *MongoDBWrapper) GetAllUsers() (a []*User, err error) {

	cursor, err := store.UsersCollection.Find(
		context.TODO(),
		bson.D{},
	)

	for cursor.Next(context.TODO()) {
		elem := &User{}

		if err := cursor.Decode(elem); err != nil {
			return nil, status.Errorf(codes.Internal, "Something went wrong!")
		}

		a = append(a, elem)
	}

	return a, nil

}

//SetVerficationCode sets a new code in the field.
func (store *MongoDBWrapper) SetVerficationCode(mail string, code string) error {
	return store.ChangeFieldValue(mail, "VerficationCode", code)
}

//ResetLastCodeRequest sets the value to current time.
func (store *MongoDBWrapper) ResetLastCodeRequest(mail string) error {
	return store.ChangeFieldValue(mail, "LastCodeRequest", time.Now().Unix())
}

//SetRefreshToken makes changes to a field name.
func (store *MongoDBWrapper) SetRefreshToken(mail string, refreshToken string) error {
	return store.ChangeFieldValue(mail, "RefreshToken", refreshToken)
}

//SetBalance sets the balance field.
func (store *MongoDBWrapper) SetBalance(mail string, balance int) error {
	return store.ChangeFieldValue(mail, "Balance", balance)
}

//ActivateUser sets the balance field.
func (store *MongoDBWrapper) ActivateUser(mail string) error {
	return store.ChangeFieldValue(mail, "Activated", true)
}

//ChangeFieldValue sets a new value in the given field name
func (store *MongoDBWrapper) ChangeFieldValue(mail string, fieldName string, value interface{}) error {

	_, err := store.UsersCollection.UpdateOne(
		context.TODO(),
		bson.D{
			{Key: "Email", Value: strings.ToLower(mail)},
		},
		bson.D{
			{Key: "$set",
				Value: bson.D{
					{Key: fieldName, Value: value},
				},
			},
		},
	)

	if err != nil {
		return status.Errorf(codes.Internal, "Something went wrong!")
	}

	return nil
}




// GetFullHistory will return a transaction array of all the transactions of the given user
func (store *MongoDBWrapper) GetFiles(mail string) ([]*File, error) {

	findOptions := options.Find()
	findOptions.SetSort(bson.M{"Time": 1}) // sort from newest to oldest

	_, err := store.GetUserByEmail(mail)
	if err != nil {
		return nil, err
	}

	cursor, err := store.TransactionsCollection.Find(context.TODO(), bson.M{"$or": []interface{}{bson.M{"Sender": mail}, bson.M{"Receiver": mail}}}, findOptions)
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Wrong mail")
	}

	senderResults := []*File{}
	if err = cursor.All(context.TODO(), &senderResults); err != nil {
		return senderResults, status.Errorf(codes.Internal, "Error trying to convert mongo data to file")
	}

	return senderResults, nil
}


// Write adds a log to the database in the logs collecitons
func (store *MongoDBWrapper) Write(message []byte) (int, error) {
	var info interface{}
	err := bson.UnmarshalExtJSON(message, true, &info)
	if err != nil {
		return 0, err
	}

	_, err = store.LogsCollection.InsertOne(
		context.TODO(),
		info,
	)

	if err != nil {
		return 0, err
	}

	return len(message), nil
}


// CheckIdentifier will check if the given device identifier was logged before, true if yes else false
func (store *MongoDBWrapper) CheckIdentifier(mail, identifier string) (bool, error) {

	user, err := store.GetUserByEmail(mail)
	if err != nil {
		return false, err
	}

	// Check if the identifier was seen before
	for _, loggedIdentifier := range user.Identifiers {
		if loggedIdentifier == identifier {
			return false, nil
		}
	}
	return true, nil
}

// AddIdentifier will add the given identifier to the DB
func (store *MongoDBWrapper) AddIdentifier(mail, identifier string) error {

	user, err := store.GetUserByEmail(mail)
	if err != nil {
		return err
	}

	// check if identifier already exists
	for _, loggedIdentifier := range user.Identifiers {
		if loggedIdentifier == identifier {
			return status.Errorf(codes.Aborted, "Identifier was already logged!")
		}
	}

	user.Identifiers = append(user.Identifiers, identifier)

	err = store.ChangeFieldValue(mail, "Identifiers", user.Identifiers)
	if err != nil {
		return err
	}

	return nil
}

// AddIdentifier will add the given identifier to the DB
func (store *MongoDBWrapper) ChangePassword(mail, newPassword string) error {

	// get the user
	_, err := store.GetUserByEmail(mail)
	if err != nil {
		return err
	}

	// generate the new hashed password
	hashedPassword, err := generatePassword(newPassword)
	if err != nil {
		return status.Errorf(codes.Internal, "Cannot hash password")
	}

	// set the new password
	err = store.ChangeFieldValue(mail, "Password", hashedPassword)
	if err != nil {
		return err
	}

	return nil
}