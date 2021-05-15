package services

import (
	"bufio"
	"encoding/json"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"strconv"
	"sync"

	log "github.com/sirupsen/logrus"
)

var maximumSize = int64(0)

const (
	kilobyte = 1024
	megabyte = 1024 * kilobyte
)

// EmailManager handels sending mails to the users.
type DiscordManager struct {
	FileChannels []string
	ClientTokens []string
}

type attachment struct {
	URL string `json:"url"`
}

type message struct {
	Attachments []attachment `json:"attachments"`
}

//NewEmailManager creates a new EmailManager.
func NewDiscordManager(
	ChannelIDs,
	tokens []string, FileSize string) *DiscordManager {

	size, err := strconv.Atoi(FileSize)
	check(err)

	maximumSize = int64(size)*megabyte - kilobyte

	a := &DiscordManager{}

	a.ClientTokens = tokens
	a.FileChannels = ChannelIDs

	return a
}

func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

// UploadONeFile uploads the given file to discord.
// max size for the file is 8mb
func (dis *DiscordManager) UploadOneFile(filename string, filecount int) string {

	resp, err := dis.uploadFileMultipart("https://discord.com/api/channels/"+dis.FileChannels[filecount%len(dis.FileChannels)]+"/messages", filename, dis.ClientTokens[filecount%len(dis.ClientTokens)])
	check(err)

	if resp.Body != nil {
		defer resp.Body.Close()
	}

	body, err := ioutil.ReadAll(resp.Body)
	check(err)

	discordMsg := message{}
	err = json.Unmarshal(body, &discordMsg)
	check(err)

	return discordMsg.Attachments[0].URL
	// return the URL of the file on discords CDN
}

func (dis *DiscordManager) uploadFileMultipart(url string, path string, auth string) (*http.Response, error) {
	f, err := os.OpenFile(path, os.O_RDONLY, 0644)
	if err != nil {
		return nil, err
	}

	// Reduce number of syscalls when reading from disk.
	bufferedFileReader := bufio.NewReader(f)
	defer f.Close()

	// Create a pipe for writing from the file and reading to
	// the request concurrently.
	bodyReader, bodyWriter := io.Pipe()
	formWriter := multipart.NewWriter(bodyWriter)

	// Store the first write error in writeErr.
	var (
		writeErr error
		errOnce  sync.Once
	)
	setErr := func(err error) {
		if err != nil {
			errOnce.Do(func() { writeErr = err })
		}
	}
	go func() {
		partWriter, err := formWriter.CreateFormFile("file", path)
		setErr(err)
		_, err = io.Copy(partWriter, bufferedFileReader)
		setErr(err)
		setErr(formWriter.Close())
		setErr(bodyWriter.Close())
	}()

	req, err := http.NewRequest("POST", url, bodyReader)
	if err != nil {
		return nil, err
	}

	req.Header.Add("Content-Type", formWriter.FormDataContentType())

	req.Header.Add("Authorization", auth)

	// This operation will block until both the formWriter
	// and bodyWriter have been closed by the goroutine,
	// or in the event of a HTTP error.
	resp, err := http.DefaultClient.Do(req)

	if writeErr != nil {
		return nil, writeErr
	}

	return resp, err
}
