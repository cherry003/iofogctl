package deploycontroller

import (
	"fmt"
	"github.com/eclipse-iofog/cli/internal/config"
	"os/user"
)

type localExecutor struct {
	opt *Options
}

func newLocalExecutor(opt *Options) *localExecutor {
	l := &localExecutor{}
	l.opt = opt
	return l
}

func (exe *localExecutor) Execute() error {
	// TODO (Serge) Execute back-end logic

	currUser, err := user.Current()
	if err != nil {
		return err
	}
	// Update configuration
	configEntry := config.Controller{
		Name: exe.opt.Name,
		User: currUser.Username,
		Host: "localhost",
	}
	err = config.AddController(exe.opt.Namespace, configEntry)

	// TODO (Serge) Handle config file error, retry..?

	if err == nil {
		fmt.Printf("\nController %s/%s successfully deployed.\n", exe.opt.Namespace, exe.opt.Name)
	}
	return err
}
