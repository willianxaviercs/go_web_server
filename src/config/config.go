package config

type Environment string

const (
	Prod Environment = "Prod"
	Dev              = "Dev"
)

type ServerConfig struct {
	Env  Environment
	Addr string
}

var Config = ServerConfig{
	Env:  Dev,
	Addr: "localhost:9001",
}
