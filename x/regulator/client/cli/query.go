package cli

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/codec"

	"github.com/allinbits/cosmos-cash-poa/x/regulator/types"
)

// GetQueryCmd returns the cli query commands for this module
func GetQueryCmd(queryRoute string, cdc *codec.Codec) *cobra.Command {
	// Group regulator queries under a subcommand
	regulatorQueryCmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      fmt.Sprintf("Querying commands for the %s module", types.ModuleName),
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}

	regulatorQueryCmd.AddCommand(
		flags.GetCommands(
	// this line is used by starport scaffolding # 1
	// TODO: Add query Cmds
		)...,
	)

	return regulatorQueryCmd
}

// TODO: Add Query Commands