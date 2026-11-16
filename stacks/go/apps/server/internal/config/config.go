// Package config is the one place that reads the environment (GO-4).
package config

import "errors"

const defaultHTTPAddr = "127.0.0.1:__P__20"

// ErrInvalidAddr is an HTTP address that is set but empty after trimming.
var ErrInvalidAddr = errors.New("invalid http address")

// Values is the validated runtime configuration.
type Values struct {
	HTTPAddr string
}

// Load reads and validates the configuration; main passes os.Getenv, tests pass a map-backed fake.
func Load(getenv func(string) string) (Values, error) {
	values := Values{HTTPAddr: valueOr(getenv("__PREFIX___HTTP_ADDR"), defaultHTTPAddr)}
	if values.HTTPAddr == "" {
		return Values{}, ErrInvalidAddr
	}
	return values, nil
}

func valueOr(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
