require 'asset_fingerprint/symlinker'
require 'asset_fingerprint/fingerprinter'
require 'asset_fingerprint/path_rewriter'

module AssetFingerprint
  
  class Asset
    
    def self.cache_enabled?
      if @@cache_enabled.nil?
        # Asset cache behaviour same as cache_asset_timestamps
        # if no value set. This is fine for most environments, you probably
        # don't need to change this.
        return ActionView::Helpers::AssetTagHelper.cache_asset_timestamps
      end
      @@cache_enabled
    end
    

    # You can enable or disable the asset cache.
    # With the cache enabled, the asset tag helper methods will make fewer
    # expensive calls. However this prevents you from modifying
    # any asset files while the server is running. Most people will
    # not need to set this as the default behaviour is sensible and tied
    # to AssetTagHelper.cache_asset_timestamps. It is safe to ignore this
    # setting.
    def self.cache_enabled=(value)
      @@cache_enabled = value
    end
    @@cache_enabled = nil
    
    @@cache = {}
    @@cache_guard = Mutex.new
    
    attr_accessor :source 
    
    def self.create(source)
      asset = @@cache[source] if cache_enabled?
      asset = Asset.new(source) if asset.nil?
      asset
    end
    
    def initialize(source)
      self.source = source
      if Asset.cache_enabled?
        @@cache_guard.synchronize do
          @@cache[source] = self
        end
      end
    end
    
    def self.absolute_path(relative_path)
      File.join(ActionView::Helpers::AssetTagHelper::ASSETS_DIR, relative_path)
    end
    
    def source_absolute_path
      @source_absoulte_path ||= Asset.absolute_path(source)
    end
    
    def fingerprinter
      AssetFingerprint.fingerprinter
    end
    
    def fingerprint
      @fingerprint ||= fingerprinter.fingerprint(self)
    end
    
    def path_rewriter
      AssetFingerprint.path_rewriter
    end
    
    def populate_fingerprinted_path
      if fingerprint.blank?
        self.fingerprinted_path = source
      else
        path_rewriter.populate_fingerprinted_path(self)
      end
    end
    
    def fingerprinted_path=(value)
      @fingerprinted_path = value
    end
    
    def fingerprinted_path
      populate_fingerprinted_path unless @fingerprinted_path
      @fingerprinted_path
    end
    
    def fingerprinted_absolute_path
      @fingerprinted_absolute_path ||= Asset.absolute_path(fingerprinted_path)
    end
    
    def build_symlink
      AssetFingerprint::Symlinker.force_execute(self)
    end
    
    def symlinkable?
      path_rewriter == FileNamePathRewriter
    end
   
    def self.generate_all_symlinks
      #assets = ['favicon.ico', 'downloads', 'images', 'javascripts', 'stylesheets']
      paths = ['favicon.ico', 'downloads']
      paths.each do |source|
        absolute_path = Asset.absolute_path(source)
        if File.file?(absolute_path)
          asset = Asset.new(source)
          asset.build_symlink
        end
      end
      #Dir['config/recipes/*.rb'].each { |recipe| load(recipe) }
    end
    
  end
  
end