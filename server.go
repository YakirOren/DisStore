package main

import (
	"os"
	"github.com/andersfylling/disgord"
	log "github.com/sirupsen/logrus"
	"github.com/joho/godotenv"
	"cloud/util"
)

// init is invoked before main()
func init() {
	// loads values from .env into the system
	if err := godotenv.Load("config.env"); err != nil {
		log.Warning("No .env file found")
	}

}

const (
	ChannelID = disgord.Snowflake(610471489128366100)
)

func main() {

	//load the config
	config, err := util.LoadConfig(".")
	if err != nil {
		log.Fatal("❌\n", err)
	}

	client := disgord.New(disgord.Config{
		BotToken: config.Token,
	})
	//defer client.Gateway().StayConnectedUntilInterrupted()
	f1, err := os.Open("index.jpg")
	if err != nil {
		panic(err)
	}
	defer f1.Close()
	f2, err := os.Open("gali-cloud.png")
	if err != nil {
		panic(err)
	}
	defer f2.Close()

	_, errUpload := client.Channel(ChannelID).CreateMessage(&disgord.CreateMessageParams{
		Content: "This is my favourite image, and another in an embed!",
		Files: []disgord.CreateMessageFileParams{
			{f1, "index.jpg", false},
			{f2, "gali-cloud.png", false},
		},
		Embed: &disgord.Embed{
			Description: "Look here!",
			Image: &disgord.EmbedImage{
				URL: "attachment://another.jpg",
			},
		},
	})
	if errUpload != nil {
		client.Logger().Error("unable to upload images.", errUpload)
	}

}
