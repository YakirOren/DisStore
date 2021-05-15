package util

import (
	"os"
	"strings"

	log "github.com/sirupsen/logrus"
)

// Config holds the config data
type Config struct {
	DiscordTokens        []string `mapstructure:"TOKENS"`
	FileChannels         []string `mapstructure:"FILE_CHANNELS"`
	FileSize             string   `mapstructure:"FILE_SIZE"`
	Port                 string   `mapstructure:"PORT"`
	AccessTokenKey       string   `mapstructure:"ACCESS_TOKEN_KEY"`
	RefreshTokenKey      string   `mapstructure:"REFRESH_TOKEN_KEY"`
	AccessTokenDuration  string   `mapstructure:"ACCESS_TOKEN_DURATION"`
	RefreshTokenDuration string   `mapstructure:"REFRESH_TOKEN_DURATION"`
	ConnectionString     string   `mapstructure:"CONNECTION_STRING"`
	DBName               string   `mapstructure:"DB_NAME"`
	UserCollection       string   `mapstructure:"USER_COLLECTION"`
	FileCollection       string   `mapstructure:"FILE_COLLECTION"`
	LogsCollection       string   `mapstructure:"LOGS_COLLECTION"`
	SystemEmail          string   `mapstructure:"SYSTEM_EMAIL"`
	SystemEmailPassword  string   `mapstructure:"SYSTEM_EMAIL_PASSWORD"`
}

// LoadConfig is used to load the config from the config file.
func LoadConfig(path string) (c Config, err error) {
	log.Infof("Loading config...")

	c.DiscordTokens = strings.Fields(os.Getenv("TOKENS"))
	c.FileChannels = strings.Fields(os.Getenv("FILE_CHANNELS"))
	c.FileSize = os.Getenv("FILE_SIZE")
	c.Port = os.Getenv("PORT")
	c.AccessTokenKey = os.Getenv("ACCESS_TOKEN_KEY")
	c.RefreshTokenKey = os.Getenv("REFRESH_TOKEN_KEY")
	c.AccessTokenDuration = os.Getenv("ACCESS_TOKEN_DURATION")
	c.RefreshTokenDuration = os.Getenv("REFRESH_TOKEN_DURATION")
	c.ConnectionString = os.Getenv("CONNECTION_STRING")
	c.DBName = os.Getenv("DB_NAME")
	c.UserCollection = os.Getenv("USER_COLLECTION")
	c.FileCollection = os.Getenv("FILE_COLLECTION")
	c.LogsCollection = os.Getenv("LOGS_COLLECTION")

	c.SystemEmail = os.Getenv("SYSTEM_EMAIL")
	c.SystemEmailPassword = os.Getenv("SYSTEM_EMAIL_PASSWORD")

	log.Infof("Done! ✅")
	return

}
