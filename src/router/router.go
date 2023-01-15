package router

import (
	"fmt"
	"io"
	"net/http"

	"github.com/julienschmidt/httprouter"
	"github.com/rs/zerolog/log"
)

func LogRequest(next httprouter.Handle) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, params httprouter.Params) {
		req := fmt.Sprintf("Method: %s | URL: %s%s | Proto: %s | Body: %s",
			r.Method, r.Host, r.URL, r.Proto, r.Body)
		log.Info().Msg(req)
		next(w, r, params)
	}
}

func Index(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	io.WriteString(w, "Hello, World!\n")
}

func NewServerRoutes() http.Handler {

	router := httprouter.New()
	router.GET("/", LogRequest(Index))

	return router
}
