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
	create "github.com/eclipse-iofog/iofogctl/internal/create/namespace"
	"github.com/eclipse-iofog/iofogctl/pkg/util"
	"github.com/spf13/cobra"
)

func newCreateNamespaceCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "namespace NAME",
		Short:   "Create a Namespace",
		Long:    `Create a Namespace`,
		Example: `iofogctl create namespace NAME`,
		Args:    cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			// Get name and namespace of agent
			name := args[0]

			// Run the command
			err := create.Execute(name)
			util.Check(err)

			util.PrintSuccess("Successfully created namespace " + name)
		},
	}

	return cmd
}
