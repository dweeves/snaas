package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"golang.org/x/net/context"

	"github.com/tapglue/snaas/core"
	"github.com/tapglue/snaas/service/app"
)

// AppCreate creates a new App.
func AppCreate(fn core.AppCreateFunc) Handler {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		p := payloadApp{}

		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			respondError(w, 0, wrapError(ErrBadRequest, err.Error()))
			return
		}

		a, err := fn(p.Name, p.Description)
		if err != nil {
			respondError(w, 0, err)
			return
		}

		respondJSON(w, http.StatusOK, &payloadApp{app: a})
	}
}

// AppList returns all apps.
func AppList(fn core.AppListFunc) Handler {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		as, err := fn()
		if err != nil {
			respondError(w, 0, err)
			return
		}

		if len(as) == 0 {
			respondJSON(w, http.StatusNoContent, nil)
			return
		}

		respondJSON(w, http.StatusOK, &payloadApps{apps: as})
	}
}

type payloadApp struct {
	app         *app.App
	Description string `json:"description"`
	Name        string `json:"name"`
}

func (p *payloadApp) MarshalJSON() ([]byte, error) {
	return json.Marshal(struct {
		BackendToken string `json:"backend_token"`
		Description  string `json:"description"`
		Enabled      bool   `json:"enabled"`
		ID           string `json:"id"`
		Name         string `json:"name"`
		Token        string `json:"token"`
	}{
		BackendToken: p.app.BackendToken,
		Description:  p.app.Description,
		Enabled:      p.app.Enabled,
		ID:           strconv.FormatUint(p.app.ID, 10),
		Name:         p.app.Name,
		Token:        p.app.Token,
	})
}

type payloadApps struct {
	apps app.List
}

func (p *payloadApps) MarshalJSON() ([]byte, error) {
	as := []*payloadApp{}

	for _, a := range p.apps {
		as = append(as, &payloadApp{app: a})
	}

	return json.Marshal(struct {
		Apps []*payloadApp `json:"apps"`
	}{
		Apps: as,
	})
}
