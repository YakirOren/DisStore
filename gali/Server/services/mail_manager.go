package services

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"net/smtp"

	log "github.com/sirupsen/logrus"
)

const (
	// smtp server configuration.
	smtpHost = "smtp.gmail.com"
	smtpPort = "587"
)

// EmailManager handels sending mails to the users.
type EmailManager struct {
	email string
	auth  smtp.Auth
}

//NewEmailManager creates a new EmailManager.
func NewEmailManager(
	Email,
	Password string) *EmailManager {

	// Authentication.
	auth := smtp.PlainAuth("", Email, Password, smtpHost)

	return &EmailManager{Email, auth}
}

func (manager *EmailManager) sendEmail(to []string, body bytes.Buffer) error {

	// Sending email.
	err := smtp.SendMail(smtpHost+":"+smtpPort, manager.auth, manager.email, to, body.Bytes())
	if err != nil {
		log.Infof("Could not send email to %s", to)
		return err
	}

	log.Infof("Email Sent! to %s", to)
	return nil
}

// SendVerficationCode sends the given user an email with code.
func (manager *EmailManager) SendVerficationCode(user *User) error {

	verficationCodeTemplate, err := template.ParseFiles("mail_templates//template.html")

	if err != nil {
		return err
	}

	var body bytes.Buffer

	mimeHeaders := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\n\n"
	body.Write([]byte(fmt.Sprintf("Subject: Payeet - Your Verification Code \n%s\n\n", mimeHeaders)))

	code := user.VerficationCode

	verficationCodeTemplate.Execute(&body, struct {
		Name string
		CODE string
	}{
		Name: strings.Title(user.FirstName) + " " + strings.Title(user.LastName),
		CODE: code,
	})

	err = manager.sendEmail([]string{user.Email}, body)
	if err != nil {
		return err
	}

	return nil
}

// SendNewLoginMessage sends the given user a mail that a login from a new device occurred
func (manager *EmailManager) SendNewLoginMessage(user *User, deviceName, deviceIP string) error {

	newLoginTemplate, err := template.ParseFiles("mail_templates//new_login_template.html")

	if err != nil {
		return err
	}

	var body bytes.Buffer

	mimeHeaders := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\n\n"
	body.Write([]byte(fmt.Sprintf("Subject: Payeet Security Alert - New Device Login \n%s\n\n", mimeHeaders)))

	newLoginTemplate.Execute(&body, struct {
		Name       string
		DeviceName string
		DeviceIP   string
	}{
		Name:       strings.Title(user.FirstName) + " " + strings.Title(user.LastName),
		DeviceName: deviceName,
		DeviceIP:   deviceIP,
	})

	err = manager.sendEmail([]string{user.Email}, body)
	if err != nil {
		return err
	}

	return nil
}

// SendNewLoginMessage sends the given user a mail that a login from a new device occurred
func (manager *EmailManager) SendResetPasswordMessage(user *User) error {

	passwordResetTemplate, err := template.ParseFiles("mail_templates//reset_password_template.html")

	if err != nil {
		return err
	}

	var body bytes.Buffer

	mimeHeaders := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\n\n"
	body.Write([]byte(fmt.Sprintf("Subject: Payeet - Password Reset Code \n%s\n\n", mimeHeaders)))

	code := user.VerficationCode

	passwordResetTemplate.Execute(&body, struct {
		Name string
		CODE string
	}{
		Name: strings.Title(user.FirstName) + " " + strings.Title(user.LastName),
		CODE: code,
	})

	err = manager.sendEmail([]string{user.Email}, body)
	if err != nil {
		return err
	}

	return nil
}
