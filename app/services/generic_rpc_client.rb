class GenericRpcClient < SiClient
  attr_reader :authentication_token

  def act_si_model(model_name, arguments, action)
    status_messages = {
      200 => "OK",
      201 => "Modified",
      500 => "Not found"
    }

    call 'generic_model.action', status_messages, action: action, model_name: model_name, authentication_token: @authentication_token, arguments: arguments, application_name: Rails.application.class.parent_name, authentication_token: authentication_token
  end

  def channel_name
    @channel_name ||= 'ecov.rpc'
  end

  def set_authentication_token(token)
    @authentication_token = token
  end

  def check_authenticated
    fail UnauthenticatedRpcClientException unless authentication_token.present?
  end

  class UnauthenticatedRpcClientException < Exception
  end
end
