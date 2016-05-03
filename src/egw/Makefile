BUCKET?=$(USER)
NAME=egw
CFN=$(NAME).json
MINCFN=$(NAME).min.json
UPLOADED=.uploaded
S3=https://s3.amazonaws.com
TEMPLATEURL=$(S3)/$(BUCKET)/$(MINCFN)
STACK=$(USER)-$(NAME)-`date +%Y%M%d-%H%M%S`

# create stack using the template
stack: $(UPLOADED)
	aws cloudformation create-stack --stack-name $(STACK) \
		--template-url $(TEMPLATEURL) --capabilities CAPABILITY_IAM \
		--parameters `jq -c '' test_params.json`

# upload tempalte top s3
$(UPLOADED): $(MINCFN)
	aws s3 cp --acl public-read $^ s3://$(BUCKET)/$^
	touch $(UPLOADED)

# remove spaces and newlines from template (compress)
$(MINCFN): $(CFN)
	jq -c '' $^ > $@

.PHONY: stack
