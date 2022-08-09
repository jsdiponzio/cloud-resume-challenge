from google.cloud import firestore

def increment_fetch(request, test=False):
    if not test:
        db = firestore.Client(project='jess-cloud-resume-challenge')
    else:
        db = test
    doc_ref = db.collection(u'visitors').document(u'count')
    doc = doc_ref.get()
    count = doc.to_dict()['visitors']

    updated_count = count + 1
    doc_ref.update({'visitors': updated_count})

    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    return (f"{updated_count}", 200, headers)