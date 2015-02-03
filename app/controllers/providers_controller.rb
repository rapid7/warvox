class ProvidersController < ApplicationController

  def index

   	@providers = Provider.order('id DESC').paginate(
		:page => params[:page],
		:per_page => 10
	)

	@new_provider = Provider.new
	@new_provider.enabled = true

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @providers }
    end
  end

  def new
    @provider = Provider.new
	@provider.enabled = true
	@provider.port = 4569

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @provider }
    end
  end

  def edit
    @provider = Provider.find(params[:id])
	@provider.pass = "********"
  end

  def create
    @provider = Provider.new(params[:provider])
	@provider.enabled = true

    respond_to do |format|
      if @provider.save
        flash[:notice] = 'Provider was successfully created.'
        format.html { redirect_to providers_path }
        format.xml  { render :xml => @provider, :status => :created, :location => providers_path }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @provider.errors, :status => :unprocessable_entity }
      end
    end
  end


  def update
    @provider = Provider.find(params[:id])

	# Dont set the password if its the placeholder
	if params[:provider] and params[:provider][:pass] and params[:provider][:pass] == "********"
		params[:provider].delete(:pass)
	end

    respond_to do |format|
      if @provider.update_attributes(params[:provider])
        flash[:notice] = 'Provider was successfully updated.'
        format.html { redirect_to providers_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @provider.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @provider = Provider.find(params[:id])
    @provider.destroy

    respond_to do |format|
      format.html { redirect_to providers_path }
      format.xml  { head :ok }
    end
  end
end
