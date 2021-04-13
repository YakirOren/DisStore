package util

import (
	"os"
	log "github.com/sirupsen/logrus"
)

// Config holds the config data
type Config struct {
	Token                          string   `mapstructure:"TOKEN"`

}

// LoadConfig is used to load the config from the config file.
func LoadConfig(path string) (c Config, err error) {
	log.Infof("Loading config...")
	c.Token = os.Getenv("TOKEN")
	log.Infof("Done! ✅")
	return

}
