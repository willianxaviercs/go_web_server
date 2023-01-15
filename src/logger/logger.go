package logger

import (
	"encoding/json"
	"os"
	"strconv"
	"strings"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

const (
	Clear  = "\033[0m"
	Bold   = "\033[1m"
	Red    = "\033[41m"
	Green  = "\033[42m"
	Yellow = "\033[43m"
	Blue   = "\033[44m"
)

var LevelToColor = map[string]string{
	"error": Red,
	"info":  Green,
	"warn":  Yellow,
	"debug": Blue,
}

type LogWriter struct {
	Wd               string
	LastLogMultiline bool
}

type LogEntry struct {
	Timestamp  string
	Level      string
	Message    string
	Error      string
	StackTrace []interface{}
}

func init() {
	log.Logger = log.Output(NewLogWriter())
}

func Info() *zerolog.Event {
	return log.Info().Timestamp().Stack()
}

func Error() *zerolog.Event {
	return log.Error().Timestamp().Stack()
}

func Warn() *zerolog.Event {
	return log.Warn().Timestamp().Stack()
}

func Debug() *zerolog.Event {
	return log.Debug().Timestamp().Stack()
}

func NewLogWriter() *LogWriter {
	wd, _ := os.Getwd()
	return &LogWriter{
		Wd:               wd,
		LastLogMultiline: false,
	}
}

func (w *LogWriter) Write(p []byte) (int, error) {

	var fields map[string]interface{}
	err := json.Unmarshal(p, &fields)

	if err != nil {
		return os.Stderr.Write(p)
	}

	var entry LogEntry

	for name, val := range fields {
		switch name {
		case zerolog.TimestampFieldName:
			entry.Timestamp = val.(string)
		case zerolog.LevelFieldName:
			entry.Level = val.(string)
		case zerolog.MessageFieldName:
			entry.Message = val.(string)
		case zerolog.ErrorStackFieldName:
			entry.StackTrace = val.([]interface{})
		}
	}

	isMultiline := (entry.Error != "" || entry.StackTrace != nil)

	var line strings.Builder
	if isMultiline || w.LastLogMultiline {
		line.WriteString("-------------------------------------------------------\n")
	}

	// timestamp
	line.WriteString(entry.Timestamp)
	line.WriteString(" ")

	// level
	line.WriteString(LevelToColor[entry.Level])
	line.WriteString(Bold)
	line.WriteString(strings.ToUpper(entry.Level))
	line.WriteString(Clear)
	line.WriteString(": ")

	// message
	line.WriteString(entry.Message)
	line.WriteString("\n")

	// error
	if entry.Error != "" {
		line.WriteString(" " + Bold + Red + "ERROR: " + Clear)
		line.WriteString(entry.Error)
		line.WriteString("\n")
	}

	// stack trace
	if entry.StackTrace != nil {
		line.WriteString(" " + Bold + Blue + "Stack trace:" + Clear + "\n")
		for _, frame := range entry.StackTrace {
			frameMap := frame.(map[string]interface{})
			file := frameMap["file"].(string)
			file = strings.Replace(file, w.Wd, ".", 1)
			line.WriteString("    ")
			line.WriteString(frameMap["function"].(string))
			line.WriteString(" (")
			line.WriteString(":")
			line.WriteString(strconv.Itoa(int(frameMap["line"].(float64))))
			line.WriteString("\n")
		}
	}

	w.LastLogMultiline = isMultiline

	return os.Stderr.Write([]byte(line.String()))
}
