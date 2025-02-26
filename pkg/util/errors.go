/*
 *  *******************************************************************************
 *  * Copyright (c) 2019 Edgeworx, Inc.
 *  *
 *  * This program and the accompanying materials are made available under the
 *  * terms of the Eclipse Public License v. 2.0 which is available at
 *  * http://www.eclipse.org/legal/epl-2.0
 *  *
 *  * SPDX-License-Identifier: EPL-2.0
 *  *******************************************************************************
 *
 */

package util

import (
	"fmt"
	"os"
)

// Check error and exit
func Check(err error) {
	if err != nil {
		PrintError(err.Error())
		os.Exit(1)
	}
}

type Error struct {
	msg string
}

func NewError(msg string) (err *Error) {
	err = new(Error)
	err.msg = msg
	return err
}

func (err *Error) Error() string {
	return err.msg
}

// NotFoundError export
type NotFoundError struct {
	msg string
}

// NewNotFoundError export
func NewNotFoundError(msg string) (err *NotFoundError) {
	err = new(NotFoundError)
	err.msg = msg
	return err
}

// Error export
func (err *NotFoundError) Error() string {
	return fmt.Sprintf("Unknown resource error\n%s", err.msg)
}

//ConflictError export
type ConflictError struct {
	msg string
}

// NewConflictError export
func NewConflictError(msg string) (err *ConflictError) {
	err = new(ConflictError)
	err.msg = msg
	return err
}

// Error export
func (err *ConflictError) Error() string {
	return fmt.Sprintf("Resource conflict error\n%s", err.msg)
}

// InputError export
type InputError struct {
	message string
}

//NewInputError export
func NewInputError(message string) (err *InputError) {
	err = new(InputError)
	err.message = message
	return err
}

// Error export
func (err *InputError) Error() string {
	return "User input error\n" + err.message
}

// InternalError export
type InternalError struct {
	message string
}

// NewInternalError export
func NewInternalError(message string) (err *InternalError) {
	err = new(InternalError)
	err.message = message
	return err
}

// Error export
func (err *InternalError) Error() string {
	return "Unexpected internal behaviour\n" + err.message
}
