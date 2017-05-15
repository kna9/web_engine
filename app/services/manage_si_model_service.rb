class ManageSIModelService
  def initialize(model_name, token, attributes)
    GenericRpcClient.initialize_connection

    # pour le site web il faut initialiser et passer le authentication_token
    # user_session['authentication_token']
    authentication_token = token

    @generic_rpc_client ||= GenericRpcClient.new
    @generic_rpc_client.set_authentication_token(authentication_token) if authentication_token

    @model_name = model_name
    @attributes = attributes
  end

  def del
    @generic_rpc_client.act_si_model(@model_name, @attributes, 'del')
  end

  def put
    @generic_rpc_client.act_si_model(@model_name, @attributes, 'put')
  end

  def check
    @generic_rpc_client.act_si_model(@model_name, @attributes, 'check')
  end
end
