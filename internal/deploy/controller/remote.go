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

package deploycontroller

import (
	"github.com/eclipse-iofog/iofogctl/internal/config"
	"github.com/eclipse-iofog/iofogctl/pkg/iofog"
	"github.com/eclipse-iofog/iofogctl/pkg/iofog/client"
	"github.com/eclipse-iofog/iofogctl/pkg/iofog/install"
)

type remoteExecutor struct {
	opt *Options
}

func newRemoteExecutor(opt *Options) *remoteExecutor {
	d := &remoteExecutor{}
	d.opt = opt
	return d
}

func (exe *remoteExecutor) Execute() (err error) {
	// Instantiate installer
	controllerOptions := &install.ControllerOptions{
		User:              exe.opt.User,
		Host:              exe.opt.Host,
		Port:              exe.opt.Port,
		PrivKeyFilename:   exe.opt.KeyFile,
		Version:           exe.opt.Version,
		PackageCloudToken: exe.opt.PackageCloudToken,
	}
	installer := install.NewController(controllerOptions)

	// Update configuration before we try to deploy in case of failure
	configEntry, err := prepareUserAndSaveConfig(exe.opt)
	if err != nil {
		return
	}

	// Install Controller and Connector
	if err = installer.Install(); err != nil {
		return
	}

	// Configure Controller and Connector
	if err = installer.Configure(client.User{
		Name:     configEntry.IofogUser.Name,
		Surname:  configEntry.IofogUser.Surname,
		Email:    configEntry.IofogUser.Email,
		Password: configEntry.IofogUser.Password,
	}); err != nil {
		return
	}

	// Update configuration
	configEntry.Endpoint = exe.opt.Host + ":" + iofog.ControllerPortString
	if err = config.UpdateController(exe.opt.Namespace, configEntry); err != nil {
		return
	}

	return config.Flush()
}
