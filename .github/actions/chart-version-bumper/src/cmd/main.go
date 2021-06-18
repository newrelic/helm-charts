package main

import (
	bumper "github.com/newrelic/chart-version-bumper"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/pflag"
	"github.com/spf13/viper"
	"path"
	"strings"
)

const chartsDir = "charts"

func main() {
	pflag.String("charts-dir", chartsDir, "Charts directory")
	pflag.String("chart", "", "Chart to bump, name must match exactly a directory in $REPOROOT/charts/")
	pflag.String("version", "", "New version for the chart")
	pflag.String("app-version", "", "New appVersion for the chart")
	pflag.Parse()

	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	viper.AutomaticEnv()
	if err := viper.BindPFlags(pflag.CommandLine); err != nil {
		log.Fatal(err)
	}

	if viper.GetString("app-version") == "" {
		log.Fatalf("-app-version must be set")
		return
	}

	if viper.GetString("chart") == "" {
		log.Fatalf("-chart must be set")
		return
	}

	bmp := &bumper.ChartBumper{
		Path: path.Join(viper.GetString("charts-dir"), viper.GetString("chart")),
	}

	err := bmp.Bump(viper.GetString("version"), viper.GetString("app-version"))
	if err != nil {
		log.Fatalf("Error bumping chart: %v", err)
	}
}
