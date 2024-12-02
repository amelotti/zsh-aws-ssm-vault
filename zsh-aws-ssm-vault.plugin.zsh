#
# Função para buscar o valor de um parâmetro no AWS Systems Manager Parameter Store
# get_ssm_parameter path_do_parametro [profile_aws]
#
get_ssm_parameter() {
    local verbose=0
    local parameter_name=""
    local aws_profile=""
    local aws_region=""

    # Verifica os argumentos
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=1
                shift
                ;;
            --profile)
                aws_profile="$2"
                shift 2
                ;;
            --region)
                aws_region="$2"
                shift 2
                ;;
            *)
                parameter_name="$1"
                shift
                ;;
        esac
    done

    # Validação do nome do parâmetro
    if [[ -z "$parameter_name" ]]; then
        echo "Erro: Nome do parâmetro não fornecido."
        return 1
    fi

    # Define o perfil AWS padrão, se não especificado
    if [[ -z "$aws_profile" ]]; then
        aws_profile=$ZSH_AWS_PROFILE
    fi

    # Monta o comando AWS CLI com região opcional
    local aws_cmd="aws --profile \"$aws_profile\""
    if [[ -n "$aws_region" ]]; then
        aws_cmd="$aws_cmd --region \"$aws_region\""
    fi

    # Busca o parâmetro usando AWS CLI
    local parameter_value
    parameter_value=$(eval "$aws_cmd ssm get-parameter --name \"$parameter_name\" --with-decryption --query \"Parameter.Value\" --output text 2>/dev/null")

    # Verifica se a busca foi bem-sucedida
    if [[ $? -ne 0 ]]; then
        if [[ $verbose -eq 1 ]]; then
            echo "Erro: Não foi possível buscar o parâmetro '$parameter_name'. Verifique se ele existe e se as permissões estão corretas."
        fi
        return 2
    fi

    # Retorna o valor do parâmetro (com ou sem comentários)
    if [[ $verbose -eq 1 ]]; then
        echo "Parâmetro solicitado: $parameter_name"
        echo "Valor do parâmetro: $parameter_value"
    else
        echo "$parameter_value"
    fi

    return 0
}


#
# Função para definir o valor de um parâmetro no AWS Systems Manager Parameter Store
#
set_ssm_parameter() {
    local verbose=0
    local parameter_name=""
    local parameter_value=""
    local parameter_type="String"  # Tipo padrão é "String"
    local aws_profile=""
    local aws_region=""  # Nova variável para região

    # Verifica os argumentos
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=1
                shift
                ;;
            --profile)
                aws_profile="$2"
                shift 2
                ;;
            --type)
                parameter_type="$2"
                shift 2
                ;;
            --name)
                parameter_name="$2"
                shift 2
                ;;
            --value)
                parameter_value="$2"
                shift 2
                ;;
            --region)
                aws_region="$2"
                shift 2
                ;;
            *)
                echo "Erro: Argumento inválido '$1'."
                return 1
                ;;
        esac
    done

    # Validação de argumentos obrigatórios
    if [[ -z "$parameter_name" || -z "$parameter_value" ]]; then
        echo "Erro: Nome (--name) e valor (--value) do parâmetro são obrigatórios."
        return 1
    fi

    # Define o perfil AWS padrão, se não especificado
    if [[ -z "$aws_profile" ]]; then
        aws_profile=$ZSH_AWS_PROFILE
    fi

    # Comando base do AWS CLI com profile
    local aws_cmd="aws --profile $aws_profile"

    # Adiciona região se especificada
    if [[ -n "$aws_region" ]]; then
        aws_cmd="$aws_cmd --region $aws_region"
    fi

    if [[ $verbose -eq 1 ]]; then
        echo "Definindo o parâmetro..."
        echo "Nome: $parameter_name"
        echo "Valor: $parameter_value"
        echo "Tipo: $parameter_type"
        echo "Profile AWS: $aws_profile"
        [[ -n "$aws_region" ]] && echo "Região AWS: $aws_region"
    fi

    $aws_cmd ssm put-parameter \
        --name "$parameter_name" \
        --value "$parameter_value" \
        --type "$parameter_type" \
        --overwrite \
        >/dev/null 2>&1

    if [[ $? -ne 0 ]]; then
        if [[ $verbose -eq 1 ]]; then
            echo "Erro: Falha ao definir ou atualizar o parâmetro '$parameter_name'."
        fi
        return 2
    fi

    if [[ $verbose -eq 1 ]]; then
        echo "Parâmetro '$parameter_name' definido com sucesso!"
    else
        echo "Parâmetro definido com sucesso!"
    fi

    return 0
}


#
# Função listar os valores dos parâmetros no AWS Systems Manager Parameter Store
#
list_ssm_parameters() {
    local verbose=0
    local include_values=0
    local aws_profile=""
    local aws_region=""
    local next_token=""

    # Verifica os argumentos
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=1
                shift
                ;;
            --profile)
                aws_profile="$2"
                shift 2
                ;;
            --region)
                aws_region="$2"
                shift 2
                ;;
            --with-values)
                include_values=1
                shift
                ;;
            *)
                echo "Erro: Argumento inválido '$1'."
                return 1
                ;;
        esac
    done

    # Define o perfil AWS padrão, se não especificado
    if [[ -z "$aws_profile" ]]; then
        aws_profile=$ZSH_AWS_PROFILE
    fi

    if [[ $verbose -eq 1 ]]; then
        echo "Listando parâmetros no Parameter Store..."
        echo "Profile AWS: $aws_profile"
        echo "Incluir valores: $include_values"
    fi

    # Adiciona a região ao comando AWS CLI se especificada
    local aws_base_cmd="aws --profile \"$aws_profile\""
    if [[ -n "$aws_region" ]]; then
        aws_base_cmd="$aws_base_cmd --region \"$aws_region\""
        if [[ $verbose -eq 1 ]]; then
            echo "Região AWS: $aws_region"
        fi
    fi

    # Lista os parâmetros (paginação caso haja muitos)
    while :; do
        local response
        if [[ -n "$next_token" ]]; then
            response=$(eval "$aws_base_cmd ssm describe-parameters --next-token \"$next_token\" --query \"{Parameters: Parameters, NextToken: NextToken}\" --output json 2>/dev/null")
        else
            response=$(eval "$aws_base_cmd ssm describe-parameters --query \"{Parameters: Parameters, NextToken: NextToken}\" --output json 2>/dev/null")
        fi

        # Verifica se a chamada foi bem-sucedida
        if [[ $? -ne 0 ]]; then
            if [[ $verbose -eq 1 ]]; then
                echo "Erro: Não foi possível listar os parâmetros. Verifique as permissões e o perfil AWS."
            fi
            return 2
        fi

        # Extrai os parâmetros e o próximo token
        local parameters
        parameters=$(echo "$response" | jq -r '.Parameters[] | .Name')
        next_token=$(echo "$response" | jq -r '.NextToken // empty')

        # Exibe os parâmetros
        for param_name in $parameters; do
            if [[ $include_values -eq 1 ]]; then
                # Obtém o valor do parâmetro
                local param_value
                param_value=$(eval "$aws_base_cmd ssm get-parameter --name \"$param_name\" --with-decryption --query \"Parameter.Value\" --output text 2>/dev/null")

                # Verifica se a busca foi bem-sucedida
                if [[ $? -ne 0 ]]; then
                    echo "Erro ao obter o valor para '$param_name'."
                    continue
                fi

                # Exibe a chave e o valor
                echo "$param_name: $param_value"
            else
                # Exibe apenas a chave
                echo "$param_name"
            fi
        done

        # Sai do loop se não houver mais páginas
        if [[ -z "$next_token" ]]; then
            break
        fi
    done

    if [[ $verbose -eq 1 ]]; then
        echo "Listagem concluída."
    fi

    return 0
}

