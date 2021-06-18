package bumper

import (
	"errors"
	"fmt"
	log "github.com/sirupsen/logrus"
	"gopkg.in/yaml.v3"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

type ChartBumper struct {
	Path string
}

func (b *ChartBumper) chartFile() (*os.File, error) {
	errFound := errors.New("found")

	targetPath := ""

	err := filepath.WalkDir(b.Path, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		lcName := strings.ToLower(d.Name())
		if lcName == "chart.yaml" || lcName == "chart.yml" {
			targetPath = path
			log.Infof("Found chart yaml file: %s", targetPath)
			return errFound
		}

		return nil
	})
	if err != nil && !errors.Is(err, errFound) {
		return nil, fmt.Errorf("searching for chart.yaml: %w", err)
	}

	if targetPath == "" {
		return nil, fmt.Errorf("could find chart.yaml file")
	}

	return os.OpenFile(targetPath, os.O_RDWR, 0o664)
}

func (b *ChartBumper) Bump(newVer, newAppVer string) error {
	file, err := b.chartFile()
	if err != nil {
		return fmt.Errorf("opening Chart.yml file: %w", err)
	}

	defer func() {
		err := file.Close()
		if err != nil {
			log.Errorf("Error closing file: %v", err)
		}
	}()

	out, err := b.bumpYaml(file, newVer, newAppVer)
	if err != nil {
		return fmt.Errorf("processing yaml file: %w", err)
	}

	log.Infof("Updating file in-place")
	_, err = file.Seek(0, 0)
	if err != nil {
		return fmt.Errorf("rewinding yaml file: %w", err)
	}

	err = file.Truncate(0)
	if err != nil {
		return fmt.Errorf("truncating yaml file: %w", err)
	}

	_, err = file.Write(out)
	if err != nil {
		return fmt.Errorf("writing patched yaml file: %w", err)
	}

	return nil
}

func (b *ChartBumper) bumpYaml(src io.Reader, newVer, newAppVer string) ([]byte, error) {
	yamlNode := yaml.Node{}
	err := yaml.NewDecoder(src).Decode(&yamlNode)
	if err != nil {
		return nil, fmt.Errorf("decoding yaml: %w", err)
	}

	node := chartNode{Node: yamlNode}

	err = node.bumpVersions(newVer, newAppVer)
	if err != nil {
		return nil, fmt.Errorf("bumping versions: %w", err)
	}

	return yaml.Marshal(&yamlNode)
}

type chartNode struct {
	yaml.Node
}

var errKeyNotFound = errors.New("key not found in yaml")

func (n *chartNode) bumpVersions(newVer, newAppVer string) error {
	appVer, err := n.versionNode("appVersion")
	if err != nil {
		return fmt.Errorf("finding current appVersion: %w", err)
	}

	ver, err := n.versionNode("version")
	if err != nil {
		return fmt.Errorf("finding current version: %w", err)
	}

	if newVer == "" {
		log.Infof("New chart version is blank, applying same bump type as appVersion")
		bump, err := findBump(appVer.Value, newAppVer)
		if err != nil {
			return fmt.Errorf("computing new version from appVersion: %w", err)
		}

		log.Infof("appVersion got a %s bump, applying the same to version", bump)
		newVer, err = applyBump(ver.Value, bump)
		if err != nil {
			return fmt.Errorf("applying computed bump to version: %w", err)
		}
	}

	log.Infof("Bumping appVersion from %s to %s", appVer.Value, newAppVer)
	appVer.Value = newAppVer

	log.Infof("Bumping version from %s to %s", ver.Value, newVer)
	ver.Value = newVer

	return nil
}

func (n *chartNode) versionNode(key string) (*yaml.Node, error) {
	if len(n.Content) == 0 {
		return nil, errKeyNotFound
	}

	// Bad and ugly hack: Assume first node is a mapping node
	// Find a node whose value is the key we are looking for, and return the next one (the value node)
	for i, node := range n.Content[0].Content {
		if node.Value == key && i+1 <= len(n.Content[0].Content) {
			return n.Content[0].Content[i+1], nil
		}
	}

	return nil, errKeyNotFound
}
