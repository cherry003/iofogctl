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

package cmd

import (
	deploy "github.com/eclipse-iofog/iofogctl/internal/deploy/agent"
	"github.com/eclipse-iofog/iofogctl/pkg/util"
	"github.com/spf13/cobra"
)

func newDeployAgentCommand() *cobra.Command {
	// Instantiate options
	opt := &deploy.Options{}

	// Instantiate command
	cmd := &cobra.Command{
		Use:   "agent NAME",
		Short: "Bootstrap and provision an edge host",
		Long: `Bootstrap an edge host with the ioFog Agent stack and provision it with a Controller.

A Controller must first be deployed within the corresponding namespace in order to provision the Agent.`,
		Example: `iofogctl deploy agent NAME --local
iofogctl deploy agent NAME --user root --host 32.23.134.3 --key-file ~/.ssh/id_rsa`,
		Args: cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			var err error

			// Get agent name and namespace
			opt.Name = args[0]
			opt.Namespace, err = cmd.Flags().GetString("namespace")
			util.Check(err)

			// Format any file paths
			opt.KeyFile, err = util.FormatPath(opt.KeyFile)
			util.Check(err)

			// Get executor for the command
			exe, err := deploy.NewExecutor(opt)
			util.Check(err)

			// Execute the command
			err = exe.Execute()
			util.Check(err)

			util.PrintSuccess("Successfully deployed " + opt.Namespace + "/" + opt.Name)
		},
	}

	// Set up options
	cmd.Flags().StringVar(&opt.User, "user", "", "Username of host the Agent is being deployed on")
	cmd.Flags().StringVar(&opt.Host, "host", "", "IP or hostname of host the Agent is being deployed on")
	cmd.Flags().IntVar(&opt.Port, "port", 22, "SSH port to use when deploying agent to host")
	cmd.Flags().StringVar(&opt.KeyFile, "key-file", "", "Filename of SSH private key used to access host. Corresponding *.pub must be in same dir. Must be RSA key.")
	cmd.Flags().BoolVarP(&opt.Local, "local", "l", false, "Configure for local deployment. Cannot be used with other flags")
	cmd.Flags().Lookup("local").NoOptDefVal = "true"

	return cmd
}
