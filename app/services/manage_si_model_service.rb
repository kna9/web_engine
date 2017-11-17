class ManageSIModelService
  def initialize(model_name, token, attributes)
    GenericRpcClient.initialize_connection

    # pour le site web il faut initialiser et passer le authentication_token
    # user_session['authentication_token']
    @authentication_token = token

    @generic_rpc_client ||= GenericRpcClient.new
    @generic_rpc_client.set_authentication_token(@authentication_token) if @authentication_token

    @model_name = model_name
    @attributes = attributes
  end

  def del
    if @model_name == "Commute"
      delete_commute
    else
      @generic_rpc_client.act_si_model(@model_name, @attributes, 'del')
    end
  end

  def put
    if @model_name == "Commute"
      declare_commute
    else
      @generic_rpc_client.act_si_model(@model_name, @attributes, 'put')
    end
  end

  def check
    @generic_rpc_client.act_si_model(@model_name, @attributes, 'check')
  end

  def declare_commute
    rpc_client = RpcClient.new_with_token(@authentication_token)

    commute_attributes = {
      start: @attributes['start_id'],
      end: @attributes['end_id'],
      time: @attributes['time'],
      time_delta: @attributes['time_delta'],
      detour_delta: @attributes['detour_delta'],
      stations: [],
      via: [],
      dow: @attributes['dow'],
      network_id: @attributes['network_id'],
      waypoints: @attributes['waypoints']
    }

    commute_attributes = commute_attributes.merge( {commute_id: @attributes['id']}) if @attributes['id'] && @attributes['id'] != nil

    retour = rpc_client.declare_commute(commute_attributes)
  end

  def delete_commute
    rpc_client = RpcClient.new_with_token(@authentication_token)

    commute_attributes = {
      commute_id: @attributes['id']
    }

    retour = rpc_client.delete_commute(commute_attributes)
  end
end
