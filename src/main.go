package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"time"

	// local
	"willianxaviercs/go_web_server/src/config"
	"willianxaviercs/go_web_server/src/logger"
	"willianxaviercs/go_web_server/src/router"
)

func main() {

	server := http.Server{
		Addr:    config.Config.Addr,
		Handler: router.NewServerRoutes(),
	}

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt)

	// SIGINT handler
	go func() {
		<-signals
		logger.Info().Msg("Shutting down server")
		go func() {
			timeout, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			server.Shutdown(timeout)
		}()
		<-signals
		logger.Warn().Msg("Forced shutting down")
		os.Exit(1)
	}()

	logger.Info().Msg("Hello, World!")
	logger.Info().Msg("Listening on http://" + config.Config.Addr)

	err := server.ListenAndServe()

	if !errors.Is(err, http.ErrServerClosed) {
		logger.Error().Err(err).Msg("Error on server initialization")
	}
}
