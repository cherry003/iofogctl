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

package logs

import (
	"github.com/eclipse-iofog/iofogctl/pkg/util"
)

type Executor interface {
	Execute() error
}

func NewExecutor(resourceType, namespace, name string) (Executor, error) {
	switch resourceType {
	case "controller":
		return newControllerExecutor(namespace, name), nil
	case "agent":
		return newAgentExecutor(namespace, name), nil
	case "microservice":
		return newMicroserviceExecutor(namespace, name), nil
	default:
		msg := "Unknown resource: '" + resourceType + "'"
		return nil, util.NewInputError(msg)
	}
}
