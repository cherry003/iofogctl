package deploycontroller

import (
	"fmt"
	"github.com/eclipse-iofog/cli/internal/config"
	"github.com/eclipse-iofog/cli/pkg/iofog"
	"github.com/eclipse-iofog/cli/pkg/util"
)

type kubernetesExecutor struct {
	opt *Options
}

func newKubernetesExecutor(opt *Options) *kubernetesExecutor {
	k := &kubernetesExecutor{}
	k.opt = opt
	return k
}

func (exe *kubernetesExecutor) Execute() (err error) {
	// Check controller already exists
	_, err = config.GetController(exe.opt.Namespace, exe.opt.Name)
	if err == nil {
		return util.NewConflictError(exe.opt.Namespace + "/" + exe.opt.Name)
	}

	// Update configuration
	configEntry := config.Controller{
		Name:       exe.opt.Name,
		KubeConfig: exe.opt.KubeConfig,
	}
	err = config.AddController(exe.opt.Namespace, configEntry)
	if err != nil {
		return
	}

	// Get Kubernetes cluster
	k8s, err := iofog.NewKubernetes(exe.opt.KubeConfig)
	if err != nil {
		return
	}

	// Create controller on cluster
	err = k8s.CreateController()
	if err != nil {
		return
	}

	fmt.Printf("\nController %s/%s successfully deployed.\n", exe.opt.Namespace, exe.opt.Name)
	return nil
}
