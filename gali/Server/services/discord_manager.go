package services

import (
	"os"

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

// UploadONeFile uploads the given file to discord.
// max size for the file is 8mb
func (dis *DiscordManager) UploadOneFile(fileData []byte, filename string) string {

	f1, err := os.Open(filename)
	check(err)
	defer f1.Close()

	// upload the file to discord, this is blocking, may want to make it async or something
	discordMsg, errUpload := dis.Client.Channel(dis.FileChannel).CreateMessage(&disgord.CreateMessageParams{
		Files: []disgord.CreateMessageFileParams{
			{Reader: f1, FileName: f1.Name(), SpoilerTag: false},
		},
	})
	check(errUpload)

	return discordMsg.Attachments[0].URL

	// return the URL of the file on discords CDN
}
