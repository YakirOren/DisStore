package services

import (
	"bytes"
	"io/ioutil"
	"os"
	"strconv"

	"github.com/andersfylling/disgord"
	log "github.com/sirupsen/logrus"
)

// EmailManager handels sending mails to the users.
type DiscordManager struct {
	FileChannel disgord.Snowflake
	Client      *disgord.Client
}

//NewEmailManager creates a new EmailManager.
func NewDiscordManager(
	channelID,
	token string) *DiscordManager {

	client := disgord.New(disgord.Config{
		BotToken: token,
	})

	return &DiscordManager{FileChannel: disgord.ParseSnowflakeString(channelID), Client: client}
}

const (
	kilobyte    = 1024
	megabyte    = 1024 * kilobyte
	maximumSize = 8*megabyte - kilobyte
)

func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

// function will fragment the given file into multiple files with maximum size of the const
// "maximumSize" and will save them to the temp folder
func fragmentFile(file bytes.Buffer, fileSize int64) {
	// file, err := os.Open(fileName)
	// check(err)
	// defer file.Close()

	// uploadFileInfo, err := file.Stat()
	// check(err)

	// fileSize := uploadFileInfo.Size()

	fileCount := fileSize/maximumSize + 1

	currSize := maximumSize
	for i := 1; int64(i) <= fileCount; i++ {
		if int64(i) == fileCount {
			currSize = int(fileSize % maximumSize)
		}

		currentBytes := make([]byte, currSize)
		readBytes, err := file.Read(currentBytes)
		check(err)

		f2, err := os.Create("temp/tmp" + strconv.Itoa(i))
		check(err)
		defer f2.Close()

		_, err = f2.Write(currentBytes)
		check(err)

		if readBytes < maximumSize {
			break
		}
	}
}

// function will defragment the files in the temp folder into one
func defragmentFile(outFileName string) {
	f, err := os.Create(outFileName)
	check(err)
	defer f.Close()

	files, err := ioutil.ReadDir("temp/")
	check(err)

	for _, file := range files {
		fileData, err := ioutil.ReadFile("temp/" + file.Name())
		check(err)

		_, err = f.Write(fileData)
		check(err)

	}
}

// UploadFile fragments the given file and sends the fragments to the discord file channel.
func (dis *DiscordManager) UploadFile(fileData bytes.Buffer, fileSize int64) (URLs []string) {

	log.Println("fragmenting file")
	fragmentFile(fileData, fileSize) // file to fragment and upload
	log.Println("done fragmenting file")

	// get all the files in the folder
	files, err := ioutil.ReadDir("temp/")
	check(err)

	for _, file := range files {
		// read the file to upload
		f1, err := os.Open("temp/" + file.Name())
		check(err)

		// upload the file to discord, this is blocking, may want to make it async or something
		discordMsg, errUpload := dis.Client.Channel(dis.FileChannel).CreateMessage(&disgord.CreateMessageParams{
			Files: []disgord.CreateMessageFileParams{
				{Reader: f1, FileName: file.Name(), SpoilerTag: false},
			},
		})
		check(errUpload)

		// close the file
		f1.Close()

		err = os.Remove("temp/" + file.Name())
		check(err)

		//  discord cdn URL of the file
		log.Println(discordMsg.Attachments[0].URL)
		URLs = append(URLs, discordMsg.Attachments[0].URL)

	}

	return URLs
	// return array of URLs from discords CDN
}
