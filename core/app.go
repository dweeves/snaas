package core

import (
	"crypto/md5"
	"fmt"
	"math/rand"
	"time"

	"github.com/tapglue/snaas/platform/generate"
	"github.com/tapglue/snaas/service/app"
)

// AppCreateFunc creates a new App.
type AppCreateFunc func(name, description string) (*app.App, error)

// AppCreate creates a new App.
func AppCreate(apps app.Service) AppCreateFunc {
	return func(name, description string) (*app.App, error) {
		token, backendToken, err := generateTokens()
		if err != nil {
			return nil, err
		}

		return apps.Put(app.NamespaceDefault, &app.App{
			BackendToken: backendToken,
			Description:  description,
			Enabled:      true,
			InProduction: false,
			Name:         name,
			Token:        token,
		})
	}
}

// AppFetchFunc returns the App for the given id.
type AppFetchFunc func(id uint64) (*app.App, error)

// AppFetch returns the App for the given id.
func AppFetch(apps app.Service) AppFetchFunc {
	return func(id uint64) (*app.App, error) {
		as, err := apps.Query(app.NamespaceDefault, app.QueryOptions{
			Enabled: &defaultEnabled,
			IDs: []uint64{
				id,
			},
		})
		if err != nil {
			return nil, err
		}

		if len(as) == 0 {
			return nil, wrapError(ErrNotFound, "app (%d) not found", id)
		}

		return as[0], nil
	}
}

func generateTokens() (string, string, error) {
	src := rand.NewSource(time.Now().UnixNano())

	tokenHash := md5.New()
	_, err := tokenHash.Write(generate.RandomBytes(src, 32))
	if err != nil {
		return "", "", err
	}
	token := fmt.Sprintf("%x", tokenHash.Sum(nil))

	backendHash := md5.New()
	_, err = backendHash.Write(generate.RandomBytes(src, 12))
	if err != nil {
		return "", "", err
	}

	return token, fmt.Sprintf(
		"%s%s",
		token,
		fmt.Sprintf("%x", backendHash.Sum(nil))[:12],
	), nil
}
