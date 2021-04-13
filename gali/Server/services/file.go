package services

import (
	"go.mongodb.org/mongo-driver/bson"
)

// File struct contains info about a File
type File struct {
	Owner   string `bson:"Owner" json:"Owner"`
	Name 	string `bson:"Name" json:"Name"`
	Fragments   []string `bson:"Fragments" json:"Fragments"`
	Time     int64  `bson:"Time" json:"Time"`
}

// ToBson truns the File object into bson
func (File *File) ToBson() bson.D {

	a := bson.D{
		{Key: "Owner", Value: File.Owner},
		{Key: "Fragments", Value: File.Fragments},
		{Key: "Name", Value: File.Name},
		{Key: "Time", Value: File.Time},
	}

	return a
}


