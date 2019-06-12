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

package deletecontroller

import (
	"fmt"
	"github.com/eclipse-iofog/iofogctl/internal/config"
	"github.com/eclipse-iofog/iofogctl/pkg/iofog"
)

type kubernetesExecutor struct {
	namespace string
	name      string
}

func newKubernetesExecutor(namespace, name string) *kubernetesExecutor {
	exe := &kubernetesExecutor{}
	exe.namespace = namespace
	exe.name = name
	return exe
}

func (exe *kubernetesExecutor) Execute() error {
	// Find the requested controller
	ctrl, err := config.GetController(exe.namespace, exe.name)
	if err != nil {
		return err
	}

	// Instantiate Kubernetes object
	k8s, err := iofog.NewKubernetes(ctrl.KubeConfig)

	// Delete Controller on cluster
	err = k8s.DeleteController()
	if err != nil {
		return err
	}

	// Update configuration
	err = config.DeleteController(exe.namespace, exe.name)
	if err != nil {
		return err
	}

	fmt.Printf("\nController %s/%s successfully deleted.\n", exe.namespace, exe.name)

	return config.Flush()
}
