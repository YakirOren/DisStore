package services

import (
	"os"

	"github.com/andersfylling/disgord"
	log "github.com/sirupsen/logrus"
)

// EmailManager handels sending mails to the users.
type DiscordManager struct {
	FileChannels []disgord.Snowflake
	Clients      []*disgord.Client
}

//NewEmailManager creates a new EmailManager.
func NewDiscordManager(
	ChannelIDs,
	tokens []string) *DiscordManager {

	a := &DiscordManager{}

	for _, t := range tokens {
		client := disgord.New(disgord.Config{
			BotToken: t,
		})
		a.Clients = append(a.Clients, client)

	}

	for _, id := range ChannelIDs {
		a.FileChannels = append(a.FileChannels, disgord.ParseSnowflakeString(id))
	}

	return a
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
func (dis *DiscordManager) UploadOneFile(fileData []byte, filename string, filecount int) string {

	f1, err := os.Open(filename)
	check(err)
	defer f1.Close()

	// upload the file to discord, this is blocking, may want to make it async or something
	discordMsg, errUpload := dis.Clients[filecount%len(dis.Clients)].Channel(dis.FileChannels[filecount%len(dis.FileChannels)]).CreateMessage(&disgord.CreateMessageParams{
		Files: []disgord.CreateMessageFileParams{
			{Reader: f1, FileName: f1.Name(), SpoilerTag: false},
		},
	})
	check(errUpload)

	return discordMsg.Attachments[0].URL

	// return the URL of the file on discords CDN
}
