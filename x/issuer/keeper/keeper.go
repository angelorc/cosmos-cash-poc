package keeper

import (
	"fmt"

	"github.com/tendermint/tendermint/libs/log"

	"github.com/allinbits/cosmos-cash-poc/x/issuer/types"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/bank"
	"github.com/cosmos/cosmos-sdk/x/supply"
)

// UnmarshalFn is a generic function to unmarshal bytes
type UnmarshalFn func(value []byte) (interface{}, bool)

// Keeper of the issuer store
type Keeper struct {
	CoinKeeper   bank.Keeper
	SupplyKeeper supply.Keeper
	storeKey     sdk.StoreKey
	cdc          *codec.Codec
	//permAddrs    map[string]types.PermissionsForAddress
}

// NewKeeper creates a issuer keeper
func NewKeeper(coinKeeper bank.Keeper, supplyKeeper supply.Keeper, cdc *codec.Codec, key sdk.StoreKey) Keeper {
	if addr := supplyKeeper.GetModuleAddress(types.ModuleName); addr == nil {
		panic(fmt.Sprintf("%s module account has not been set", types.ModuleName))
	}

	keeper := Keeper{
		CoinKeeper:   coinKeeper,
		SupplyKeeper: supplyKeeper,
		storeKey:     key,
		cdc:          cdc,
	}
	return keeper
}

// Logger returns a module-specific logger.
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", fmt.Sprintf("x/%s", types.ModuleName))
}

// Set sets a value in the db with a prefixed key
func (k Keeper) Set(ctx sdk.Context, key []byte, prefix []byte, i interface{}) {
	store := ctx.KVStore(k.storeKey)
	store.Set(append(prefix, key...), k.cdc.MustMarshalBinaryBare(i))
}

// Get gets an item from the store by bytes
func (k Keeper) Get(ctx sdk.Context, key []byte, prefix []byte, unmarshal UnmarshalFn) (i interface{}, found bool) {
	store := ctx.KVStore(k.storeKey)
	value := store.Get(append(prefix, key...))

	return unmarshal(value)
}

// GetAll values from with a prefix from the store
func (k Keeper) GetAll(ctx sdk.Context, prefix []byte, unmarshal UnmarshalFn) (i []interface{}) {
	store := ctx.KVStore(k.storeKey)
	iterator := sdk.KVStorePrefixIterator(store, prefix)
	defer iterator.Close()

	for ; iterator.Valid(); iterator.Next() {
		value, _ := unmarshal(iterator.Value())
		i = append(i, value)
	}
	return i
}
