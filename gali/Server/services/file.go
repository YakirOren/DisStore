package services

import (
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// File struct contains info about a File
type File struct {
	ID        primitive.ObjectID `bson:"_id" json:"id,omitempty"`
	Owner     string             `bson:"Owner" json:"Owner"`
	Name      string             `bson:"Name" json:"Name"`
	Fragments []string           `bson:"Fragments" json:"Fragments"`
	Time      int64              `bson:"Time" json:"Time"`
	FileSize  float64            `bson:"FileSize" json:"FileSize"`
}

// ToBson truns the File object into bson
func (File *File) ToBson() bson.D {

	a := bson.D{
		{Key: "Owner", Value: File.Owner},
		{Key: "Fragments", Value: File.Fragments},
		{Key: "Name", Value: File.Name},
		{Key: "Time", Value: File.Time},
		{Key: "FileSize", Value: File.FileSize},
	}

	return a
}
