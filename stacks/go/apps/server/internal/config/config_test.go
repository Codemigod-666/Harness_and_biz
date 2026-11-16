package config_test

import (
	"testing"

	"__MODULE__/apps/server/internal/config"
)

func envOf(values map[string]string) func(string) string {
	return func(key string) string { return values[key] }
}

func TestLoad(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name string
		env  map[string]string
		want string
	}{
		{name: "unset keeps the default", env: nil, want: "127.0.0.1:__P__20"},
		{name: "set overrides the default", env: map[string]string{"__PREFIX___HTTP_ADDR": "127.0.0.1:9"}, want: "127.0.0.1:9"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			got, err := config.Load(envOf(test.env))

			if err != nil {
				t.Fatalf("load: %v", err)
			}
			if got.HTTPAddr != test.want {
				t.Errorf("HTTPAddr = %q, want %q", got.HTTPAddr, test.want)
			}
		})
	}
}
