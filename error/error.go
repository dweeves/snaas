package error

import (
	"errors"
	"fmt"
)

const errFmt = "%s: %s"

// General-purpose errors.
var (
	ErrNotFound = errors.New("not found")
)

// Platform errors.
var (
	ErrInvalidPlatform = errors.New("invalid platform")
)

// Error wrapper.
type Error struct {
	err error
	msg string
}

func (e Error) Error() string {
	return e.msg
}

// IsInvalidPlatform indicates if err is ErrInvalidPlatform.
func IsInvalidPlatform(err error) bool {
	return unwrapError(err) == ErrInvalidPlatform
}

// IsNotFound indicates if err is ErrNotFouund.
func IsNotFound(err error) bool {
	return unwrapError(err) == ErrNotFound
}

// Wrap constructs an Error with proper messaaging.
func Wrap(err error, format string, args ...interface{}) error {
	return &Error{
		err: err,
		msg: fmt.Sprintf(
			errFmt,
			err, fmt.Sprintf(format, args...),
		),
	}
}

func unwrapError(err error) error {
	switch e := err.(type) {
	case *Error:
		return e.err
	}

	return err
}
