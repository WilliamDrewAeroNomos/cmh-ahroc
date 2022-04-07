def handler(event, context):

    h = float(event['hour'])
    print(h)

    return {
        'As a float': h
    }