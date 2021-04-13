package services

import (
	"context"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
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

	SetBonuses(
		dailyBonusString,
		streakBonusString,
		minimumRequiredTransferDaysString,
		minimumRequiredTransferAmountString,
		karmaMultiplierFactorString,
		minimumRequiredUniqueUsersString,
		maximumTransfersToSameUserString string)

	AddUser(user *User) error
	AddTransaction(t *Transaction) error

	GetUserByEmail(mail string) (*User, error)
	GetAllUsers() (a []*User, err error)

	SetRefreshToken(mail string, refreshToken string) error
	SetBalance(mail string, balance int) error
	GetBalance(mail string) (int, error)

	AddFriend(mail, friendMail string) error
	RemoveFriend(mail, friendMail string) error

	GetMailsByStart(search string) ([]string, error)

	GetFollowers(mail string) ([]string, error)

	GetFullHistory(mail string) ([]*Transaction, error)

	Write(message []byte) (int, error) // we must implement an io.Writer function to log into mongo

	GetLastLogin(mail string) (time.Time, error)
	DailyBonus(mail string) error

	GetTransactionsInLastDays(mail string) ([]*Transaction, error)
	CalculateNewKarma(mail string) (float64, error)

	GetFiveFriendsTransfers(mail string) ([]*Transaction, error)
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

	BaseDailyBonus                int
	StreakDailyBonus              float64
	MinimumRequiredTransferDays   int
	MinimumRequiredTransferAmount int
	KarmaMultiplierFactor         float64
	MinimumRequiredUniqueUsers    int
	MaximumTransfersToSameUser    int
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

// SetBonuses sets the daily bonus and the karma constants
func (store *MongoDBWrapper) SetBonuses(
	dailyBonusString,
	streakBonusString,
	minimumRequiredTransferDaysString,
	minimumRequiredTransferAmountString,
	karmaMultiplierFactorString,
	minimumRequiredUniqueUsersString,
	maximumTransfersToSameUserString string) {

	dailyBonus, err := strconv.Atoi(dailyBonusString)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.BaseDailyBonus = dailyBonus

	streakBonus, err := strconv.ParseFloat(streakBonusString, 64)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.StreakDailyBonus = streakBonus

	minimumRequiredTransferDays, err := strconv.Atoi(minimumRequiredTransferDaysString)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.MinimumRequiredTransferDays = minimumRequiredTransferDays

	minimumRequiredTransferAmount, err := strconv.Atoi(minimumRequiredTransferAmountString)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.MinimumRequiredTransferAmount = minimumRequiredTransferAmount

	karmaMultiplierFactor, err := strconv.ParseFloat(karmaMultiplierFactorString, 64)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.KarmaMultiplierFactor = karmaMultiplierFactor

	minimumRequiredUniqueUsers, err := strconv.Atoi(minimumRequiredUniqueUsersString)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.MinimumRequiredUniqueUsers = minimumRequiredUniqueUsers

	maximumTransfersToSameUser, err := strconv.Atoi(maximumTransfersToSameUserString)
	if err != nil {
		log.Fatal("❌\n", err)
	}
	store.MaximumTransfersToSameUser = maximumTransfersToSameUser

	log.Info("Set the bonuses 📈")
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

// AddTransaction adds a new transaction to the transaction collection.
func (store *MongoDBWrapper) AddTransaction(t *Transaction) error {

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

// GetBalance returns the balance of the given user's mail.
func (store *MongoDBWrapper) GetBalance(mail string) (int, error) {

	user, err := store.GetUserByEmail(mail)
	if err != nil {
		return -1, status.Errorf(codes.Internal, "Something went wrong!")
	}

	balance := user.Balance

	return balance, nil
}

// AddFriend gets user's mail and adds the firend mail to the friend list
func (store *MongoDBWrapper) AddFriend(mail, friendMail string) error {

	// check if tries to add itself
	if mail == friendMail {
		return status.Errorf(codes.Aborted, "Cannot add yourself as friend")
	}

	// check to see if the friend exists
	_, err := store.GetUserByEmail(friendMail)
	if err != nil {
		return err
	}

	user, err := store.GetUserByEmail(mail)
	if err != nil {
		return err
	}

	// check if already a friend with them
	for _, friend := range user.Friends {
		if friend == friendMail {
			return status.Errorf(codes.Aborted, "Already friends!")
		}
	}

	user.Friends = append(user.Friends, friendMail)

	err = store.ChangeFieldValue(mail, "Friends", user.Friends)
	if err != nil {
		return err
	}

	return nil
}

// RemoveFriend gets user's mail and removes the firend mail from the friend list
func (store *MongoDBWrapper) RemoveFriend(mail, friendMail string) error {

	user, err := store.GetUserByEmail(mail)
	if err != nil {
		return status.Errorf(codes.Internal, "")
	}

	// find the index of the friend mail and remove him, if not found return error
	for i, friend := range user.Friends {
		if friend == friendMail {
			// in order to remove the friend we swap the last element in the friend list with the index we found and discard the last element
			user.Friends[len(user.Friends)-1], user.Friends[i] = user.Friends[i], user.Friends[len(user.Friends)-1]
			user.Friends = user.Friends[:len(user.Friends)-1]

			err = store.ChangeFieldValue(mail, "Friends", user.Friends)
			if err != nil {
				return err
			}

			return nil
		}
	}

	return status.Errorf(codes.NotFound, "No such friend")
}

// GetMailsByStart will get the mails of the users for a user by his search
func (store *MongoDBWrapper) GetMailsByStart(search string) ([]string, error) {
	cursor, err := store.UsersCollection.Find(context.TODO(), bson.M{"Email": bson.M{"$regex": "(?i).*" + regexp.QuoteMeta(strings.ToLower(search)) + ".*@"}})
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "Wrong mail")
	}

	users := []*User{}

	if err = cursor.All(context.TODO(), &users); err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	results := []string{}

	for _, user := range users {
		results = append(results, user.Email)
	}

	return results, nil
}

// GetFullHistory will return a transaction array of all the transactions of the given user
func (store *MongoDBWrapper) GetFullHistory(mail string) ([]*Transaction, error) {

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

	senderResults := []*Transaction{}
	if err = cursor.All(context.TODO(), &senderResults); err != nil {
		return senderResults, status.Errorf(codes.Internal, "Error trying to convert mongo data to transactions")
	}

	return senderResults, nil
}

// GetFollowers fetches all the users the follow the user
func (store *MongoDBWrapper) GetFollowers(mail string) ([]string, error) {

	cursor, err := store.UsersCollection.Find(context.TODO(), bson.M{"Friends": mail})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	followers := []*User{}

	if err = cursor.All(context.TODO(), &followers); err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	followersMail := []string{}
	for _, follower := range followers {
		followersMail = append(followersMail, follower.Email)
	}

	return followersMail, nil
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

// GetLastLogin will return the time of the last time the user logged in
func (store *MongoDBWrapper) GetLastLogin(mail string) (time.Time, error) {

	findOptions := options.FindOne()
	findOptions.SetSort(bson.M{"time": -1})

	var loginLog map[string]interface{}

	err := store.LogsCollection.FindOne(context.TODO(), bson.M{"msg": "Login", "email": mail}, findOptions).Decode(&loginLog)
	if err != nil {
		return time.Now(), status.Errorf(codes.Internal, "Something went wrong!")
	}

	// parse the time and return time object
	loginTime, err := time.Parse(time.RFC3339, loginLog["time"].(string))
	if err != nil {
		return time.Now(), status.Errorf(codes.Internal, "Something went wrong!")
	}

	return loginTime, nil
}

// DailyBonus will add the user's daily bonus to his account and update the new multiplier
func (store *MongoDBWrapper) DailyBonus(mail string) error {
	lastLogin, err := store.GetLastLogin(mail)
	if err != nil {
		return err
	}

	now := time.Now()
	midnight := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	// if he logged in before todays midnight
	if lastLogin.Unix() < midnight.Unix() {
		user, err := store.GetUserByEmail(mail)
		if err != nil {
			return err
		}

		bonus := store.BaseDailyBonus

		// if he logged in after yesterdays midnight give him the daily bonus
		if lastLogin.Unix() > midnight.Add(-24*time.Hour).Unix() {

			bonus += int(float64(bonus) * user.DailyLoginMultiplier)
			user.DailyLoginMultiplier = user.DailyLoginMultiplier + store.StreakDailyBonus

		} else { // reset his login multiplier
			user.DailyLoginMultiplier = 1
		}

		// multiply by the karma bonus
		newKarma, err := store.CalculateNewKarma(mail)
		if err != nil {
			return status.Errorf(codes.Internal, "Something went wrong!")
		}

		user.Karma += newKarma
		bonus = int(float64(bonus) * user.Karma)

		store.SetBalance(mail, user.Balance+bonus)
		store.ChangeFieldValue(mail, "Karma", user.Karma)
		store.ChangeFieldValue(mail, "DailyLoginMultiplier", user.DailyLoginMultiplier)
		log.WithFields(logrus.Fields{"email": mail, "bonus": bonus}).Info("DailyBonus")
	}

	return nil
}

// GetTransactionsInLastDays will return an array of transactions that occured in the last MinimumRequiredTransferDays days
func (store *MongoDBWrapper) GetTransactionsInLastDays(mail string) ([]*Transaction, error) {
	unixTimeDaysAgo := time.Now().Add(time.Duration(store.MinimumRequiredTransferDays) * -24 * time.Hour).Unix()
	cursor, err := store.TransactionsCollection.Find(context.TODO(), bson.M{"Sender": mail, "Time": bson.M{"$gt": unixTimeDaysAgo}})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	transactions := []*Transaction{}

	if err = cursor.All(context.TODO(), &transactions); err != nil {
		return nil, status.Errorf(codes.Internal, "Something went wrong!")
	}

	return transactions, nil
}

// CalculateNewKarma will calculate and return the chnge in the user's karma
func (store *MongoDBWrapper) CalculateNewKarma(mail string) (float64, error) {
	transactions, err := store.GetTransactionsInLastDays(mail)
	if err != nil {
		return 0, err
	}

	var karma float64

	hasTransferedToSameUser := false
	uniqueUsers := make(map[string]int) // used as a set
	amount := 0
	for _, transaction := range transactions {
		amount += transaction.Amount
		uniqueUsers[transaction.Receiver]++
	}

	for _, count := range uniqueUsers {
		if count >= store.MaximumTransfersToSameUser {
			hasTransferedToSameUser = true
		}
	}

	// chenge karma as the user transfered more then the minimum in the last days
	if amount > store.MinimumRequiredTransferAmount {
		karma += store.KarmaMultiplierFactor
	} else {
		karma -= store.KarmaMultiplierFactor
	}

	// chenge karma as the user transfered to unique users
	if len(uniqueUsers) >= store.MinimumRequiredUniqueUsers {
		karma += store.KarmaMultiplierFactor
	} else {
		karma -= store.KarmaMultiplierFactor
	}

	// subtract karma if the user transfered to the same person to many times
	if hasTransferedToSameUser {
		karma -= store.KarmaMultiplierFactor
	}

	return karma, nil
}

// GetFiveFriendsTransfers will fetch the 5 latest friend's transactions of the user
func (store *MongoDBWrapper) GetFiveFriendsTransfers(mail string) ([]*Transaction, error) {

	user, err := store.GetUserByEmail(mail)
	if err != nil {
		return nil, err
	}

	transactions := []*Transaction{}

	for _, friendMail := range user.Friends {
		friend, err := store.GetUserByEmail(friendMail)
		if err != nil {
			return nil, err
		}

		cursor, err := store.TransactionsCollection.Find(context.TODO(), bson.M{"Sender": friend.Email})
		if err != nil {
			return nil, status.Errorf(codes.NotFound, "Wrong mail")
		}

		friendTransactions := []*Transaction{}
		if err = cursor.All(context.TODO(), &friendTransactions); err != nil {
			return nil, status.Errorf(codes.Internal, "Something went wrong!")
		}

		for _, transaction := range friendTransactions {
			transactions = append(transactions, transaction)
		}
	}

	// sort the transactions
	sort.Slice(transactions, func(first, second int) bool {
		return transactions[first].Time > transactions[second].Time
	})

	if len(transactions) >= 5 {
		return transactions[:5], nil
	}

	return transactions, nil
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
	for _, loggedIdentifier := range user.Friends {
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
