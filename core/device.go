package core

import (
	"github.com/tapglue/snaas/platform/sns"
	"github.com/tapglue/snaas/service/app"
	"github.com/tapglue/snaas/service/device"
)

var defaultDeleted = false

// DeviceDeleteFunc removes the device of a user.
type DeviceDeleteFunc func(*app.App, Origin, string) error

// DeviceDelete removes the device of a user.
func DeviceDelete(devices device.Service) DeviceDeleteFunc {
	return func(
		currentApp *app.App,
		origin Origin,
		deviceID string,
	) error {
		ds, err := devices.Query(currentApp.Namespace(), device.QueryOptions{
			Deleted: &defaultDeleted,
			DeviceIDs: []string{
				deviceID,
			},
			UserIDs: []uint64{
				origin.UserID,
			},
		})
		if err != nil {
			return err
		}

		if len(ds) == 0 {
			return nil
		}

		d := ds[0]
		d.Deleted = true

		_, err = devices.Put(currentApp.Namespace(), d)

		return err
	}
}

// DeviceDisableFunc disables the device for the given endpointARN.
type DeviceDisableFunc func(currentApp *app.App, endpointARN string) error

// DeviceDisable disables the device for the given endpointARN.
func DeviceDisable(devices device.Service) DeviceDisableFunc {
	return func(currentApp *app.App, endpointARN string) error {
		ds, err := devices.Query(currentApp.Namespace(), device.QueryOptions{
			Deleted: &defaultDeleted,
			EndpointARNs: []string{
				endpointARN,
			},
		})
		if err != nil {
			return err
		}

		if len(ds) == 0 {
			return nil
		}

		d := ds[0]
		d.Disabled = true

		_, err = devices.Put(currentApp.Namespace(), d)

		return err
	}
}

// DeviceListUserFunc returns all devices for origin.
type DeviceListUserFunc func(
	currentApp *app.App,
	origin uint64,
) (device.List, error)

// DeviceListUser returns all devices for origin.
func DeviceListUser(devices device.Service) DeviceListUserFunc {
	return func(currentApp *app.App, origin uint64) (device.List, error) {
		return devices.Query(currentApp.Namespace(), device.QueryOptions{
			Deleted:  &defaultDeleted,
			Disabled: &defaultDeleted,
			Platforms: []device.Platform{
				device.PlatformIOSSandbox,
				device.PlatformIOS,
				device.PlatformAndroid,
			},
			UserIDs: []uint64{
				origin,
			},
		})
	}
}

// DeviceSyncEndpointFunc assures symmetry between the representation of the
// Device in the device.Service and SNS.
// * create endpoint if not present
// * sync tokens if different
type DeviceSyncEndpointFunc func(
	currentApp *app.App,
	platformARN string,
	input *device.Device,
) (*device.Device, error)

// DeviceSyncEndpointFunc assures symmetry between the representation of the
// Device in the device.Service and SNS Platform Application.
// * create endpoint if not present
// * sync tokens if different
func DeviceSyncEndpoint(
	devices device.Service,
	endpointCreate sns.EndpointCreateFunc,
	endpointRetrieve sns.EndpointRetrieveFunc,
	endpointUpdate sns.EndpointUpdateFunc,
) DeviceSyncEndpointFunc {
	return func(
		currentApp *app.App,
		platformARN string,
		input *device.Device,
	) (*device.Device, error) {
		// Create a new Endpoint for the device if none was created before.
		if input.EndpointARN == "" {
			e, err := endpointCreate(platformARN, input.Token)
			if err != nil {
				return nil, err
			}

			input.EndpointARN = e.ARN

			return devices.Put(currentApp.Namespace(), input)
		}

		e, err := endpointRetrieve(input.EndpointARN)
		if err != nil && !sns.IsEndpointNotFound(err) {
			return nil, err
		}

		// If the Endpoint is gone we create a new one.
		if sns.IsEndpointNotFound(err) {
			e, err := endpointCreate(platformARN, input.Token)
			if err != nil {
				return nil, err
			}

			input.EndpointARN = e.ARN

			return devices.Put(currentApp.Namespace(), input)
		}

		// Check if Tokens match.
		if input.Token != e.Token {
			_, err := endpointUpdate(input.EndpointARN, input.Token)
			if err != nil {
				return nil, err
			}
		}

		return input, nil
	}
}

// DeviceUpdateFunc stores the device data and updates the endpoint.
type DeviceUpdateFunc func(
	currentApp *app.App,
	origin Origin,
	deviceID string,
	platform device.Platform,
	token string,
	language string,
) error

// DeviceUpdate stores the device info in the given device service.
func DeviceUpdate(devices device.Service) DeviceUpdateFunc {
	return func(
		currentApp *app.App,
		origin Origin,
		deviceID string,
		platform device.Platform,
		token string,
		language string,
	) error {
		ds, err := devices.Query(currentApp.Namespace(), device.QueryOptions{
			Deleted: &defaultDeleted,
			DeviceIDs: []string{
				deviceID,
			},
			UserIDs: []uint64{
				origin.UserID,
			},
		})
		if err != nil {
			return err
		}

		if len(ds) > 0 && ds[0].Token == token {
			return nil
		}

		var d *device.Device

		if len(ds) > 0 {
			d = ds[0]
			d.Disabled = false
			d.Token = token
		} else {
			d = &device.Device{
				DeviceID: deviceID,
				Disabled: false,
				Language: language,
				Platform: platform,
				Token:    token,
				UserID:   origin.UserID,
			}
		}

		_, err = devices.Put(currentApp.Namespace(), d)
		if err != nil {
			if device.IsInvalidDevice(err) {
				return wrapError(ErrInvalidEntity, "%s", err)
			}
		}

		return err
	}
}