module WebEngine
  class RpcClient < SiClient
    def self.new_with_token(token)
      client = RpcClient.new
      client.set_authentication_token(token)
      client
    end

    def sign_in_user(args)
      status_messages = {
        200 => I18n.t('user.sign_in.signed_in'),
        404 => I18n.t('user.sign_in.error.unknown_number'),
        401 => I18n.t('user.sign_in.error.wrong_password')
      }

      call 'user.sign_in', status_messages, args
    end

    def confirm_user(args)
      status_messages = {
        200 => I18n.t('user.confirmation.confirmed'),
        404 => I18n.t('user.confirmation.error.unknown_user'),
        401 => I18n.t('user.confirmation.error.incorrect_code')
      }

      call 'user.confirm', status_messages, args
    end

    def get_dbcommute(args) # FIXME : replace with simple commute
      status_messages = {
        200 => 'DbCommute trouvé'
      }

      # FIXME pour récupérer sur le SI
      call 'dbcommute.get', status_messages, args
    end

    def get_all_commutes(args)
      status_messages = {
        200 => 'DbCommute trouvé'
      }

      # FIXME pour récupérer sur le SI
      call 'dbcommute.get_all_commutes', status_messages, args
    end

    def get_all_commutes_for_user(args)
      status_messages = {
        200 => 'DbCommute trouvé'
      }

      # FIXME pour récupérer sur le SI
      call 'dbcommute.get_all_commutes_for_user', status_messages, args
    end

    def get_all_commutes_for_station(args)
      status_messages = {
        200 => 'DbCommute trouvé'
      }

      # FIXME pour récupérer sur le SI
      call 'dbcommute.get_all_commutes_for_station', status_messages, args
    end
    
    def get_all_commutes_for_station_and_destination(args)
      status_messages = {
        200 => 'DbCommute trouvé'
      }

      # FIXME pour récupérer sur le SI
      call 'dbcommute.get_all_commutes_for_station_and_destination', status_messages, args
    end

    def get_all_commutes_for_station_and_user(args)
      status_messages = {
        200 => 'DbCommute trouvé'
      }

      # FIXME pour récupérer sur le SI
      call 'dbcommute.get_all_commutes_for_station_and_user', status_messages, args
    end

    def get_trip(args)
      status_messages = {
        200 => 'Trip trouvé'
      }

      # call 'trip.get', status_messages, args
      call 'trip.get', status_messages, args
    end

    ## FIXME: test

    def get_model(args)
      status_messages = {
        200 => 'Model trouvé'
      }

      # call 'trip.get', status_messages, args
      call 'dbmodel.get_model', status_messages, args
    end

    ##

    def get_user(phone)
      status_messages = {
        200 => I18n.t('user.identified')
      }

      call 'user.get', status_messages,
           phone: phone
      # station_id: station_id
      # ,request_id: request_id
    end

    def create_user(args)
      status_messages = {
        200 => I18n.t('user.sign_up.created'),
        409 => I18n.t('user.sign_up.error.phone_already_existing', phone_number: args[:phone])
      }

      call 'user.create', status_messages, args
    end

    def update_user(args)
      check_authenticated
      status_messages = {
        200 => I18n.t('user.updated')
      }

      params = {
        authentication_token: authentication_token
      }
      params.merge!(args)

      call 'user.update', status_messages, params
    end


    def declare_commute(args)
      check_authenticated
      status_messages = {
        403 => 'Invalid authtoken',
        404 => 'Commute id not found'
      }
      params = {
        authentication_token: authentication_token,
        action: 'put'
      }
      params.merge!(args)

      call 'user.declare_commute', status_messages, params
    end

    def delete_commute(args)
      check_authenticated
      status_messages = {
        403 => 'Invalid authtoken',
        404 => 'Commute id not found'
      }
      params = {
        authentication_token: authentication_token,
        action: 'delete'
      }
      params.merge!(args)

      call 'user.declare_commute', status_messages, params
    end

    def channel_name
      @channel_name ||= 'ecov.rpc'
    end

    attr_reader :authentication_token

    def set_authentication_token(token)
      @authentication_token = token
    end

    def check_authenticated
      fail UnauthenticatedRpcClientException unless authentication_token.present?
    end

    class UnauthenticatedRpcClientException < Exception
    end
  end
end
