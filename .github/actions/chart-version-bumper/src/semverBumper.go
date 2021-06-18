package bumper

import (
	"fmt"
	"github.com/masterminds/semver"
)

type BumpType string

const (
	BumpNone  = "none"
	BumpPatch = "patch"
	BumpMinor = "minor"
	BumpMajor = "major"
)

func findBump(old, new string) (BumpType, error) {
	oldV, err := semver.NewVersion(old)
	if err != nil {
		return BumpNone, fmt.Errorf("processing %s as a semver tag: %w", old, err)
	}

	newV, err := semver.NewVersion(new)
	if err != nil {
		return BumpNone, fmt.Errorf("processing %s as a semver tag: %w", new, err)
	}

	switch {
	case newV.Major() > oldV.Major():
		return BumpMajor, nil
	case newV.Minor() > oldV.Minor():
		return BumpMinor, nil
	case newV.Patch() > oldV.Patch():
		return BumpPatch, nil
	}

	return BumpNone, nil
}

func applyBump(old string, t BumpType) (string, error) {
	v, err := semver.NewVersion(old)
	if err != nil {
		return "", fmt.Errorf("processing %s as a semver tag: %w", old, err)
	}

	newV := *v
	switch t {
	case BumpPatch:
		newV = v.IncPatch()
	case BumpMinor:
		newV = v.IncMinor()
	case BumpMajor:
		newV = v.IncMajor()
	}

	return newV.String(), nil
}
